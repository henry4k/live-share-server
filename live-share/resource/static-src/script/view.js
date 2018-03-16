import { Observable } from 'rxjs';
import { createStore } from './utils';
import { Upload } from './Upload';
import { ImageView, VideoView } from './MediaView';
import { insertEntryAtFront } from './grid';

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
