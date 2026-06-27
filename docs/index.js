const canvas = document.querySelector("canvas");
const ctx = canvas.getContext("2d");
const transitions = buildTransitions();
let ringBuffer;
let width;
let height;
let tick;
let minTick = 0;
let zoom = 8;
let interval = undefined;
let timeout = undefined;
let darkMode = matchMedia("(prefers-color-scheme: dark)").matches;

const data = new Uint8Array(64 * 64);
data[0] = 1;
data[20 * 64 + 19] = 2;
loadState(data, 64);
render();

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
}

function toggleTheme()
{
	darkMode = !darkMode;
	render();
}
