import { Observable } from 'rxjs';
import { Upload } from './Upload';
import { promiseFromRequest, promiseFromObservable } from './utils.js';
import { InfiniScroll } from './InfiniScroll';

function requestUploads(referenceUpload, // can be null
                        direction, // 'before', 'after'
                        count) {
    console.log(`requestUploads(${referenceUpload ? 'upload' : 'null'}, ${direction}, ${count})`);

    let time;
    if(referenceUpload)
        time = referenceUpload.time;
    else
        time = new Date(Date.now());

    const order = (direction === 'before') ? 'desc' : 'asc';

    const url = `/upload/query?limit=${count}&order_${order}=time&${direction}=${time.toISOString()}`;

    const request = new XMLHttpRequest();
    request.responseType = 'json';

    const uploadStream = Observable.fromPromise(promiseFromRequest(request))
        .do(() => {
            if(request.responseType !== 'json')
                throw new Error('Invalid response type.');
            if(!Array.isArray(request.response))
                throw new Error('Invalid response.');
        })
        .mergeMap(() => Observable.from(request.response)) // unpack received array
        .map(uploadProps => new Upload(uploadProps));

    request.open('GET', url);
    request.send();

    return promiseFromObservable(uploadStream.toArray());
}

function createUploadPlaceholderElement() {
    const element = document.createElement('a');
    element.classList.add('upload-entry');
    element.href = '';
    return element;
}

function replacePlaceholder(placeholder, upload) {
    // Ghetto implementation:
    const parent = placeholder.parentElement;
    parent.replaceChild(upload.listEntry, placeholder);
}

export function init() {
    return new InfiniScroll({
        element: document.getElementById('upload-list'),
        scrollElement: document.documentElement,
        scrollEventSource: window,
        requestEntries: requestUploads,
        createEntryPlaceholderElement: createUploadPlaceholderElement,
        replacePlaceholder: replacePlaceholder
    });
}
