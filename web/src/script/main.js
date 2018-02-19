//import { Observable } from 'rxjs';

import { Upload } from './Upload';
import { ImageView, VideoView } from './MediaView';

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
    request.addEventListener('load', function(e) {
        if(request.responseType !== 'json')
            throw new Error('Invalid response type.');

        for(let uploadProps of request.response) {
            const upload = new Upload(uploadProps);
            prependUploadEntry(upload);
        }
    });
    request.open('GET', url);
    request.send();
}

window.addEventListener('load', function(e) {
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
    updatesEventSource.addEventListener('new-upload', function(e) {
        const message = JSON.parse(e.data);
        const upload = new Upload(message);
        prependUploadEntry(upload);
        setViewedUpload(upload);
    });

    uploadViewElement.addEventListener('click', function(e) { beginClearViewedUpload();
        e.preventDefault();
    });
    for(let childElement of uploadViewElement.childNodes) {
        childElement.addEventListener('click', function(e) {
            e.stopPropagation();
        });
    }
    window.addEventListener('keydown', function(e) {
        if(e.key === 'Escape') {
            beginClearViewedUpload();
            e.preventDefault();
        }
    });
});
