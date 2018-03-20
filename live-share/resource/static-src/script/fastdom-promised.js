import fastdom from 'fastdom';

const tasks = new Map();

function create(promised, method, fn, ctx) {
    let task;
    const promise = new Promise(function(resolve, reject) {
        task = fastdom[method](function() {
            tasks.delete(promise);
            try {
                resolve(ctx ? fn.call(ctx) : fn());
            } catch(e) {
                reject(e);
            }
        }, ctx);
    });
    tasks.set(promise, task);
    return promise;
}

export async function mutate(fn, ctx) {
    return create(this, 'mutate', fn, ctx);
}

export async function measure(fn, ctx) {
    return create(this, 'measure', fn, ctx);
}

export function clear(promise) {
    const task = tasks.get(promise);
    fastdom.clear(task);
    tasks.delete(promise);
}
