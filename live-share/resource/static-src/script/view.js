import { Observable } from 'rxjs';
import { createStore } from './utils';
import { Upload } from './Upload';
import { ImageView, VideoView } from './MediaView';
import { test } from './test';

var uploadViewElement        = null;
var uploadPlaceholderElement = null;
var uploadImage              = null;
var uploadVideo              = null;
var uploadDetailsElement     = null;
var uploadListElement        = null;

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

        request.response.forEach(uploadProps => {
            const upload = new Upload(uploadProps);
            prependUploadEntry(upload);
        });
    });
    */
    request.open('GET', url);
    request.send();
}

export function init() {
    uploadViewElement        = document.getElementById('upload-view');
    uploadPlaceholderElement = document.getElementById('upload-placeholder');
    uploadImage              = new ImageView(document.getElementById('upload-image'));
    uploadVideo              = new VideoView(document.getElementById('upload-video'));
    uploadDetailsElement     = document.getElementById('upload-details');

    uploadImage.reset();
    uploadVideo.reset();

    uploadViewElement.addEventListener('click', function(e) {
        beginClearViewedUpload();
        e.preventDefault();
    });
    uploadViewElement.childNodes.forEach(childElement => {
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
}
