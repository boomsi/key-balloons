import { readFile } from 'node:fs/promises';
import { createConnection } from 'node:net';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { createInterface } from 'node:readline';

const events = ['mouse.left', 'mouse.right', 'mouse.wheel'];
const action = process.argv[2];

function defaultDescriptorPath() {
    const data = process.platform === 'win32'
        ? process.env.LOCALAPPDATA
        : join(homedir(), 'Library', 'Application Support');
    return join(data, 'Key Balloons', 'mouse-feedback-v1.json');
}

async function run() {
    if (action !== 'watch' && !events.includes(action))
        throw new Error(`Usage: node mouse-feedback.mjs ${['watch', ...events].join('|')}`);

    const descriptorPath = process.env.KEY_BALLOONS_MOUSE_DESCRIPTOR || defaultDescriptorPath();
    const descriptor = JSON.parse(await readFile(descriptorPath, 'utf8'));
    if (descriptor.version !== 1 || typeof descriptor.endpoint !== 'string' || !descriptor.endpoint)
        throw new Error('The mouse feedback endpoint descriptor is invalid.');

    const watching = action === 'watch';
    const request = watching
        ? { version: 1, op: 'subscribe' }
        : { version: 1, op: 'publish', event: action };
    const socket = createConnection(descriptor.endpoint);
    socket.once('connect', () => socket.write(`${JSON.stringify(request)}\n`));
    const lines = createInterface({ input: socket, crlfDelay: Infinity });
    let acknowledged = false;
    try {
        for await (const line of lines) {
            const message = JSON.parse(line);
            if (message.op === 'error')
                throw new Error(`Key Balloons response: ${message.code}`);
            console.log(line);
            if (message.op === 'ok' && message.request === request.op) {
                acknowledged = true;
                if (!watching)
                    return;
            }
        }
        if (!acknowledged)
            throw new Error('Key Balloons disconnected before acknowledging the request.');
    } finally {
        socket.destroy();
    }
}

try {
    await run();
} catch (error) {
    console.error(error.message);
    process.exitCode = 1;
}
