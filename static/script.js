'use strict';

var uploadImageElement = null;
var uploadVideoElement = null;
var uploadDetailsElement = null;
var uploadListElement = null;

function Upload(props)
{
    this.id = props.id;
    this.time = props.time;
    this.author = props.user_name;
    this.category = props.category_name;
    this.mediaType = props.media_type;

    //const mediaUrl = '/uploads/'+id;
    const thumbnailUrl = 'https://i.imgur.com/nbHpbsob.jpg'; //'/thumbnails/'+id;

    // List Entry:
    const categoryEl = document.createElement('span');
    categoryEl.innerHTML = this.category;

    const authorEl = document.createElement('span');
    authorEl.innerHTML = this.author;

    const listEntry = document.createElement('a');
    listEntry.appendChild(categoryEl);
    listEntry.appendChild(authorEl);
    listEntry.style.backgroundImage = "url('"+thumbnailUrl+")";
    listEntry.href = '#';
    const upload = this;
    listEntry.onclick = function() { setViewedUpload(upload); };

    this.listEntry = listEntry;
}

function appendUploadEntry(upload)
{
    uploadListElement.appendChild(upload.listEntry);
}

function resetViewedUpload()
{
    uploadImageElement.src = '';
    uploadVideoElement.src = '';
    uploadImageElement.style.display = 'none';
    uploadVideoElement.style.display = 'none';
}

function setViewedUpload(upload)
{
    console.log(upload);
    resetViewedUpload();
    if(upload.mediaType == 'image')
    {
        uploadImageElement.src = '/upload/'+upload.id;
        uploadImageElement.style.display = 'initial';
    }
    else
    {
        uploadVideoElement.src = '/upload/'+upload.id;
        uploadVideoElement.style.display = 'initial';
    }
}

window.addEventListener('load', function(e)
{
    uploadImageElement = document.getElementById('upload-image');
    uploadVideoElement = document.getElementById('upload-video');
    uploadDetailsElement = document.getElementById('upload-details');
    uploadListElement = document.getElementById('upload-list');

    const eventSource = new EventSource('/updates');
    eventSource.addEventListener('new-upload', function(e)
    {
        const message = JSON.parse(e.data);
        const upload = new Upload(message);
        appendUploadEntry(upload);
        setViewedUpload(upload);
    });
});
