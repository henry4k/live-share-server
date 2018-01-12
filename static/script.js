'use strict';

var uploadImageElement = null;
var uploadVideoElement = null;
var uploadDetailsElement = null;
var uploadListElement = null;

/**
 * @param id user id
 * @param type image or video
 * @param author user name
 * @param category
 */
function Upload(id, type, author, category)
{
    this.id = id;
    this.type = type;
    this.author = author;
    this.category = category;

    //const mediaUrl = '/uploads/'+id;
    const thumbnailUrl = 'https://i.imgur.com/nbHpbsob.jpg'; //'/thumbnails/'+id;

    // List Entry:
    const categoryEl = document.createElement('span');
    categoryEl.innerHTML = category;

    const authorEl = document.createElement('span');
    authorEl.innerHTML = author;

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
    console.log(upload.type, upload);
    resetViewedUpload();
    if(upload.type == 'image')
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
        const upload = new Upload(message.id,
                                  message.type,
                                  message.user,
                                  message.category);
        appendUploadEntry(upload);
        setViewedUpload(upload);
    });

    /*
    const u1 = new Upload(42, 'image', 'henry', 'wurst');
    appendUploadEntry(u1);

    const u2 = new Upload(42, 'video', 'henry', 'brot');
    appendUploadEntry(u2);

    setViewedUpload(u2);
    */
});
