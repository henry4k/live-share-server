import { Observable } from 'rxjs';
import { createStore } from './utils';
import { Upload } from './Upload';
import { ImageView, VideoView } from './MediaView';
import { ViewPlaceholder } from './ViewPlaceholder';

let overlayElement       = null;
let uploadDetailsElement = null;
let uploadPlaceholder    = null;
let uploadImage          = null;
let uploadVideo          = null;

function clearViewedUpload() {
    console.log('clearViewedUpload');
    uploadPlaceholder.clear();
    uploadImage.reset();
    uploadVideo.reset();
    overlayElement.classList.add('hidden');
    overlayElement.removeEventListener('transitionend', clearViewedUpload);
}

function beginClearViewedUpload() {
    console.log('beginClearViewedUpload');
    overlayElement.classList.add('hidden');
    overlayElement.addEventListener('transitionend', clearViewedUpload);
}

function onMediaViewReady() {
    console.log('onMediaViewReady');
    uploadPlaceholder.beginClear();
}

export function setViewedUpload(upload) {
    console.log('setViewedUpload');
    uploadPlaceholder.set(upload.thumbnailUrl,
                          upload.width,
                          upload.height);

    let mediaView;
    if(upload.mediaType === 'image')
        mediaView = uploadImage;
    else
        mediaView = uploadVideo;
    mediaView.set(upload.url, upload.width, upload.height);

    overlayElement.classList.remove('hidden');
}

export function init() {
    overlayElement       = document.getElementById('upload-view-overlay');
    uploadDetailsElement = document.getElementById('upload-details');
    uploadPlaceholder    = new ViewPlaceholder(document.getElementById('upload-placeholder'));
    uploadImage          = new ImageView(document.getElementById('upload-image'), onMediaViewReady);
    uploadVideo          = new VideoView(document.getElementById('upload-video'), onMediaViewReady);

    uploadImage.reset();
    uploadVideo.reset();

    overlayElement.addEventListener('click', function(e) {
        beginClearViewedUpload();
        e.preventDefault();
    });
    overlayElement.childNodes.forEach(childElement => {
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
