const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");
const transitions = buildTransitions();
let ringBuffer;
let width;
let height;
let tick;
let minTick = 0;
let zoom = 8;
let cursor = undefined;
let cursorMode = 1;
let showGrid = false;
let interval = undefined;
let timeout = undefined;
let darkMode;
try
{
	darkMode = JSON.parse(localStorage.getItem("photon-game-dark"));
}
catch
{
}
darkMode ??= matchMedia("(prefers-color-scheme: dark)").matches;

document.addEventListener("paste", paste);

try
{
	if (location.hash.length > 1)
	{
		const bytes = Uint8Array.fromBase64(location.hash.substring(1));
		const w = bytes[0] | (bytes[1] << 8);
		const decoded = [];
		let curByte = 0;
		for (let i = 2; i < bytes.length; i++)
		{
			const byte = bytes[i];
			if ((byte & 0xC0) === 0xC0)
			{
				const len = (byte & 0x3F) + 2;
				for (let j = 0; j < len; j++)
					decoded.push(curByte);
			}
			else
			{
				decoded.push(byte);
				curByte = byte;
			}
		}
		const h = w === 0 ? 0 : Math.floor((decoded.length) / w);
		const data = new Uint8Array(w * h * 4);
		for (let y = 0; y < h; y++)
		{
			for (let x = 0; x < w; x++)
			{
				const byte = decoded[y * w + x];
				data[(y * 2) * w * 2 + (x * 2)] = byte & 3;
				data[(y * 2) * w * 2 + (x * 2 + 1)] = (byte >> 2) & 3;
				data[(y * 2 + 1) * w * 2 + (x * 2)] = (byte >> 4) & 3;
				data[(y * 2 + 1) * w * 2 + (x * 2 + 1)] = (byte >> 6) & 3;
			}
		}
		loadState(data, w * 2);
	}
}
catch
{
}

if (!ringBuffer)
{
	const data = new Uint8Array(64 * 64);
	data[0] = 1;
	data[20 * 64 + 19] = 2;
	loadState(data, 64);
}

function buildTransitions()
{
	const transitions = new Uint8Array(256).fill(255);
	const rules = [
		[[0, 0, 0, 0], [0, 0, 0, 0]],
		[[1, 0, 0, 0], [0, 0, 0, 1]],
		[[1, 1, 0, 0], [0, 0, 1, 1]],
		[[1, 0, 0, 1], [1, 0, 0, 1]],
		[[1, 1, 0, 1], [1, 0, 1, 1]],
		[[1, 1, 1, 1], [1, 1, 1, 1]],
		[[2, 0, 0, 0], [2, 0, 0, 0]],
		[[2, 1, 0, 0], [2, 0, 0, 1]],
		[[2, 0, 0, 1], [2, 0, 0, 0]],
		[[2, 1, 1, 0], [2, 0, 0, 1]],
		[[2, 1, 0, 1], [2, 0, 1, 1]],
		[[2, 1, 1, 1], [2, 1, 1, 0]],
		[[2, 2, 0, 0], [2, 2, 0, 0]],
		[[2, 2, 1, 0], [2, 2, 0, 1]],
		[[2, 2, 1, 1], [2, 2, 1, 1]],
		[[2, 0, 0, 2], [2, 0, 0, 2]],
		[[2, 1, 0, 2], [2, 0, 1, 2]],
		[[2, 1, 1, 2], [2, 1, 1, 2]],
		[[2, 2, 2, 0], [2, 2, 2, 1]],
		[[2, 2, 2, 1], [2, 2, 2, 1]],
		[[2, 2, 2, 2], [2, 2, 2, 2]],
	]
	const rot = ([a, b, c, d]) => [c, a, d, b];
	const flip = ([a, b, c, d]) => [b, a, d, c];
	const symmetries = [
		x => x,
		x => rot(x),
		x => rot(rot(x)),
		x => rot(rot(rot(x))),
		x => flip(x),
		x => rot(flip(x)),
		x => rot(rot(flip(x))),
		x => rot(rot(rot(flip(x)))),
	];

	for (let i = 0; i < rules.length; i++)
	{
		for (let j = 0; j < symmetries.length; j++)
		{
			const from = symmetries[j](rules[i][0]);
			const to = symmetries[j](rules[i][1]);
			const fromIndex = from[0] | (from[1] << 2) | (from[2] << 4) | (from[3] << 6);
			const toIndex = to[0] | (to[1] << 2) | (to[2] << 4) | (to[3] << 6);
			if (transitions[fromIndex] === 255)
				transitions[fromIndex] = toIndex;
			else if (transitions[fromIndex] !== toIndex)
			{
				debugger;
				throw new Error("Rules are not symmetric");
			}
		}
	}

	for (let i = 0; i < transitions.length; i++)
	{
		if ((((i & 0b10101010) >> 1) & i) === 0 && transitions[i] === 255)
		{
			debugger;
			throw new Error("Rules are not comprehensive");
		}
	}

	return transitions;
}

function loadState(data, w)
{
	width = w;
	height = Math.floor(data.length / w);
	resizeCanvas();
	tick = 0;
	ringBuffer = new Array(1024);
	ringBuffer[0] = data;
	for (let i = 1; i < ringBuffer.length; i++)
	{
		ringBuffer[i] = new Uint8Array(data.length);
	}
	render();
}

async function share()
{
	const data = ringBuffer[tick % ringBuffer.length];
	const offset = tick % 2;
	let w = width + offset;
	let h = height + offset;
	if (w % 2 === 1)
		w++;
	if (h % 2 === 1)
		h++;

	const rleEncoded = [(w >> 1) & 0xFF, (w >> 9) & 0xFF];
	let curByte = 0;
	let curLen = 0;
	for (let y = 0; y < h; y += 2)
	{
		for (let x = 0; x < w; x += 2)
		{
			let byte = 0;
			let dataX = x - offset;
			let dataY = y - offset;
			if (dataX >= 0 && dataY >= 0)
				byte |= data[dataY * width + dataX];
			if (dataX + 1 < width && dataY >= 0)
				byte |= data[dataY * width + dataX + 1] << 2;
			if (dataX >= 0 && dataY + 1 < height)
				byte |= data[(dataY + 1) * width + dataX] << 4;
			if (dataX + 1 < width && dataY + 1 < height)
				byte |= data[(dataY + 1) * width + dataX + 1] << 6;

			if (byte === curByte && curLen > 0)
			{
				curLen++;
				continue;
			}
			if (curLen > 0)
			{
				rleEncoded.push(curByte);
				curLen--;
				while (curLen > 0)
				{
					if (curLen === 1)
					{
						rleEncoded.push(curByte);
						curLen--;
					}
					else
					{
						const len = Math.min(63, curLen);
						rleEncoded.push(0xC0 | (len - 2));
						curLen -= len;
					}
				}
			}

			curByte = byte;
			curLen = 1;
		}
	}
	if (curLen > 0)
	{
		rleEncoded.push(curByte);
		curLen--;
		while (curLen > 0)
		{
			if (curLen === 1)
			{
				rleEncoded.push(curByte);
				curLen--;
			}
			else
			{
				const len = Math.min(63, curLen);
				rleEncoded.push(0xC0 | (len - 2));
				curLen -= len;
			}
		}
	}
	const link = document.getElementById("copyable-link");
	link.href = `#${new Uint8Array(rleEncoded).toBase64()}`;
	link.textContent = "Shareable link";

	const imageData = ctx.createImageData(w, h);

	for (let i = 0; i < imageData.data.length; i++)
		imageData.data[i] = 255;

	for (let y = 0; y < height; y++)
	{
		for (let x = 0; x < width; x++)
		{
			const val = data[y * width + x];
			switch (val)
			{
				case 1:
					imageData.data[((y + offset) * w + (x + offset)) * 4 + 0] = 0;
					imageData.data[((y + offset) * w + (x + offset)) * 4 + 1] = 0xCC;
					imageData.data[((y + offset) * w + (x + offset)) * 4 + 2] = 0;
					break;
				case 2:
					imageData.data[((y + offset) * w + (x + offset)) * 4 + 0] = 0;
					imageData.data[((y + offset) * w + (x + offset)) * 4 + 1] = 0;
					imageData.data[((y + offset) * w + (x + offset)) * 4 + 2] = 0;
					break;
			}
		}
	}

	const copyableCanvas = document.getElementById("copyable-canvas");
	copyableCanvas.width = w;
	copyableCanvas.height = h;
	const copyableCtx = copyableCanvas.getContext("2d");
	copyableCtx.putImageData(imageData, 0, 0);
	document.getElementById("share-message").textContent = "The above image or link can be copied to the clipboard. An image can be pasted into the page to load it.";
}

async function paste(event)
{
	for (const item of event.clipboardData.items)
	{
		if (item.type.startsWith("image/"))
		{
			event.preventDefault();
			const file = item.getAsFile();
			const bitmap = await createImageBitmap(file);
			const offscreenCanvas = new OffscreenCanvas(bitmap.width, bitmap.height);
			const offscreenCtx = offscreenCanvas.getContext("2d");
			offscreenCtx.drawImage(bitmap, 0, 0);
			const imageData = offscreenCtx.getImageData(0, 0, bitmap.width, bitmap.height);
			const data = new Uint8Array(imageData.width * imageData.height);
			for (let y = 0; y < imageData.height; y++)
			{
				for (let x = 0; x < imageData.width; x++)
				{
					const r = imageData.data[(y * imageData.width + x) * 4 + 0];
					const g = imageData.data[(y * imageData.width + x) * 4 + 1];
					if (r < 128)
						data[y * imageData.width + x] = g < 128 ? 2 : 1;
				}
			}
			loadState(data, imageData.width);
			return;
		}
	}
}

function step()
{
	const data = ringBuffer[tick % ringBuffer.length];
	const newData = ringBuffer[(tick + 1) % ringBuffer.length];
	newData.set(data);
	for (let y = tick % 2; y < height - 1; y += 2)
	{
		for (let x = tick % 2; x < width - 1; x += 2)
		{
			const ul = data[y * width + x];
			const ur = data[y * width + x + 1];
			const ll = data[(y + 1) * width + x];
			const lr = data[(y + 1) * width + x + 1];
			const index = ul | (ur << 2) | (ll << 4) | (lr << 6);
			const newIndex = transitions[index];
			newData[y * width + x] = newIndex & 3;
			newData[y * width + x + 1] = (newIndex >> 2) & 3;
			newData[(y + 1) * width + x] = (newIndex >> 4) & 3;
			newData[(y + 1) * width + x + 1] = (newIndex >> 6) & 3;
		}
	}

	// Clear photons from edge cells
	for (let x = 0; x < width; x++)
	{
		if (tick % 2 === 1 && data[x] === 1)
			newData[x] = 0;
		if (tick % 2 !== height % 2 && data[(height - 1) * width + x] === 1)
			newData[(height - 1) * width + x] = 0;
	}
	for (let y = 0; y < height; y++)
	{
		if (tick % 2 === 1 && data[y * width] === 1)
			newData[y * width] = 0;
		if (tick % 2 !== width % 2 && data[y * width + width - 1] === 1)
			newData[y * width + width - 1] = 0;
	}

	tick++;
	minTick = Math.max(minTick, tick + 1 - ringBuffer.length);
	render();
	
	if (interval !== undefined)
		timeout = setTimeout(step, interval);
}

function go(newInterval)
{
	if (interval === newInterval)
	{
		stop();
		return;
	}
	stop();
	interval = newInterval;
	step();
}

function stop()
{
	interval = undefined;
	if (timeout !== undefined)
	{
		clearTimeout(timeout);
		timeout = undefined;
	}
}

function back()
{
	if (tick <= minTick)
		return;

	stop();
	tick--;
	render();
}

function resizeCanvas()
{
	canvas.width = width * zoom;
	canvas.height = height * zoom;
}

function render()
{
	document.documentElement.style.colorScheme = darkMode ? "dark" : "light";

	ctx.fillStyle = darkMode ? "black" : "white";
	ctx.fillRect(0, 0, canvas.width, canvas.height);
	
	const data = ringBuffer[tick % ringBuffer.length];
	for (let y = 0; y < height; y++)
	{
		for (let x = 0; x < width; x++)
		{
			const val = data[y * width + x];
			switch (val)
			{
				case 1:
					ctx.fillStyle = "#00cc00";
					ctx.fillRect(x * zoom, y * zoom, zoom, zoom);
					break;
				case 2:
					ctx.fillStyle = darkMode ? "white" : "black";
					ctx.fillRect(x * zoom, y * zoom, zoom, zoom);
					break;
			}
		}
	}

	if (cursor)
	{
		ctx.strokeStyle = cursorMode === 1 ? "#00cc00" : (darkMode ? "white" : "black");
		ctx.strokeRect(cursor.x * zoom + 0.5, cursor.y * zoom + 0.5, zoom - 1, zoom - 1);
	}

	if (showGrid && zoom >= 4)
	{
		ctx.fillStyle = "#7f7f7f";
		for (let y = tick % 2; y <= height; y += 2)
		{
			for (let x = tick % 2; x <= width; x += 2)
			{
				ctx.fillRect((x - 0.125) * zoom, (y - 0.125) * zoom, zoom * 0.25, zoom * 0.25);
			}
		}
	}
}

function zoomIn(event)
{
	event.preventDefault();
	if (event.deltaY < 0)
		zoom = Math.min(zoom * 2, 32);
	else if (event.deltaY > 0)
		zoom = Math.max(zoom * 0.5, 1);
	resizeCanvas();
	render();
}

function mouse(event)
{
	let x = Math.floor(event.offsetX / zoom);
	let y = Math.floor(event.offsetY / zoom);
	if (x < 0 || x >= width || y < 0 || y >= height)
	{
		cursor = undefined;
		render();
		return;
	}
	const data = ringBuffer[tick % ringBuffer.length];
	cursor = { x, y };
	switch (event.buttons)
	{
		case 1:
			data[y * width + x] = cursorMode;
			break;
		case 2:
			data[y * width + x] = 0;
			break;
	}
	render();
}

function toggleGrid()
{
	showGrid = !showGrid;
	render();
}

function toggleTheme()
{
	darkMode = !darkMode;
	render();
	localStorage.setItem("photon-game-dark", JSON.stringify(darkMode));
}
