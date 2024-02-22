import { Vm6502 } from './vm6502.mjs';
import fs from 'node:fs/promises';
import path from 'node:path';
import util from 'node:util';

const parseCommandLine = () => {
    try {
        const { values, positionals } = util.parseArgs({
            options: {
                load: {
                    type: 'string',
                    short: 'l',
                    default: '0000'
                },
                start: {
                    type: 'string',
                    short: 's'
                },
                trace: {
                    type: 'string',
                    short: 't'
                }
            },
            allowPositionals: true
        });

        if (!/[0-9a-fA-F]{4}/.test(values.load)) {
            throw new Error('invalid command line; load address');
        }

        if (values.start !== undefined && !/[0-9a-fA-F]{4}/.test(values.start)) {
            throw new Error('invalid command line; start address');
        }

        if (values.trace !== undefined && values.trace !== 'pc' && values.trace !== 'full') {
            throw new Error('invalid command line; trace');
        }

        if (positionals.length > 1) {
            throw new Error('invalid command line; too many parameters');
        }

        return {
            load: Number.parseInt(values.load, 16),
            start: values.start !== undefined ? Number.parseInt(values.start, 16) : undefined,
            trace: values.trace,
            imagePath: positionals[0]
        };
    } catch (error) {
        console.error(error.message);
        console.log('Usage: node main.mjs [(--load|-l) c000] [(--start|-s) 0000] [(--trace|-t) (pc|full)] msbasic/tmp/vm6502.bin');
        process.exit(1);
    }
};

const loadSymbols = async (imgPath) => {
    const parsedPath = path.parse(imgPath);
    const symbolPath = path.format({ ...parsedPath, base: undefined, ext: 'lbl' });

    let symbolData;
    try {
        symbolData = await fs.readFile(symbolPath, 'utf8');
    } catch {
        // No symbols found
        return;
    }

    return Object.fromEntries(symbolData.trim().split(/\r?\n/).map((line) => {
        const m = line.match(/al ([\dA-F]+) \.(.*)/);
        return [Number.parseInt(m[1], 16), m[2]];
    }));
};

const main = async () => {
    const { load, start, trace, imagePath } = parseCommandLine();

    const image = [...await fs.readFile(imagePath)];
    const symbols = await loadSymbols(imagePath);

    const mem = [];
    for (let idx = 0; idx < image.length; idx++) {
        mem[load + idx] = image[idx];
    }

    const vm = new Vm6502(mem, symbols);
    if (start !== undefined) {
        vm.pc = start;
    }

    vm.trace = trace;

    vm.run();
};

await main();