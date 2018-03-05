import { Observable } from 'rxjs';
import { createStore } from './utils';
import { Upload } from './Upload';
import { ImageView, VideoView } from './MediaView';
import { InfiniScroll } from './InfiniScroll';

var uploadViewElement        = null;
var uploadPlaceholderElement = null;
var uploadImage              = null;
var uploadVideo              = null;
var uploadDetailsElement     = null;
var uploadListElement        = null;

function prependUploadEntry(upload) {
    const firstChild = uploadListElement.firstChild;
    uploadListElement.insertBefore(upload.listEntry, firstChild);
}

function setUploadPlaceholder(imageUrl, width, height) {
    const element = uploadPlaceholderElement;
    element.src = imageUrl;
    element.style.display = '';
    element.style.width  = ''+width+'px';
    element.style.height = ''+height+'px';
}

function clearUploadPlaceholder() {
    const element = uploadPlaceholderElement;
    element.src = '';
    element.style.display = 'none';
    element.removeEventListener('transitionend',    clearUploadPlaceholder);
    element.removeEventListener('transitioncancel', clearUploadPlaceholder);
}

function beginClearUploadPlaceholder() {
    const element = uploadPlaceholderElement;
    element.classList.add('hidden');
    element.addEventListener('transitionend',    clearUploadPlaceholder);
    element.addEventListener('transitioncancel', clearUploadPlaceholder);
}

function clearViewedUpload() {
    uploadImage.reset();
    uploadVideo.reset();
    uploadViewElement.removeEventListener('transitionend',    clearViewedUpload);
    uploadViewElement.removeEventListener('transitioncancel', clearViewedUpload);
}

function beginClearViewedUpload() {
    uploadViewElement.classList.add('hidden');
    uploadViewElement.addEventListener('transitionend',    clearViewedUpload);
    uploadViewElement.addEventListener('transitioncancel', clearViewedUpload);
}

function setViewedUpload(upload) {
    setUploadPlaceholder(upload.thumbnailUrl,
                         upload.width,
                         upload.height);

    let mediaView;
    if(upload.mediaType === 'image')
        mediaView = uploadImage;
    else
        mediaView = uploadVideo;
    mediaView.set(upload.url, upload.width, upload.height);

    uploadViewElement.classList.remove('hidden');
}

function getLatestUploads(count) {
    const now = new Date(Date.now());
    const url = '/upload/query?limit='+count+'&order_asc=time&before='+now.toISOString();
    const request = new XMLHttpRequest();
    request.responseType = 'json';

    Observable.fromEvent(request, 'load')
        .do(() => {
            if(request.responseType !== 'json')
                throw new Error('Invalid response type.');
        })
        .mergeMap(() => Observable.from(request.response)) // unpack received array
        .map(uploadProps => new Upload(uploadProps))
        .subscribe(prependUploadEntry);
    /*
    request.addEventListener('load', function(e) {
        if(request.responseType !== 'json')
            throw new Error('Invalid response type.');

        request.response.every(uploadProps => {
            const upload = new Upload(uploadProps);
            prependUploadEntry(upload);
        });
    });
    */
    request.open('GET', url);
    request.send();
}

import { List } from 'immutable';

function testRx() {
    const pressX = Observable.fromEvent(window, 'keydown')
        .filter(e => e.key === 'x');

    const pressY = Observable.fromEvent(window, 'keydown')
        .filter(e => e.key === 'y');

    let i = 1;

    // generates state changing functions
    const increase = pressX.map(() => oldState => oldState.push(i++));
    const decrease = pressY.map(() => oldState => oldState.shift());

    const store = createStore(List());
    increase.subscribe(store);
    decrease.subscribe(store);

    store.map(state => state.toJS())
         .subscribe(console.log);
}

window.addEventListener('load', function(e) {
    //testRx();
    const uploadList = document.getElementById('upload-list-outer');
    const infiniScroll = new InfiniScroll(uploadList.children[0],
                                          uploadList.children[1],
                                          uploadList.children[2]);

/*
    uploadViewElement        = document.getElementById('upload-view');
    uploadPlaceholderElement = document.getElementById('upload-placeholder');
    uploadImage              = new ImageView(document.getElementById('upload-image'));
    uploadVideo              = new VideoView(document.getElementById('upload-video'));
    uploadDetailsElement     = document.getElementById('upload-details');
    uploadListElement        = document.getElementById('upload-list');

    uploadImage.reset();
    uploadVideo.reset();

    getLatestUploads(100);

    const updatesEventSource = new EventSource('/updates');
    Observable.fromEvent(updatesEventSource, 'new-upload')
        .subscribe(function(e) {
            const message = JSON.parse(e.data);
            const upload = new Upload(message);
            prependUploadEntry(upload);
            setViewedUpload(upload);
        });

    uploadViewElement.addEventListener('click', function(e) {
        beginClearViewedUpload();
        e.preventDefault();
    });
    uploadViewElement.childNodes.every(childElement => {
        childElement.addEventListener('click', function(e) {
            e.stopPropagation();
        });
    });
    Observable.fromEvent(window, 'keydown')
        .filter(e => e.key === 'Escape')
        .subscribe(function(e) {
            beginClearViewedUpload();
            e.preventDefault();
        });
*/
});
