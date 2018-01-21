'use strict';

function loadImage(url)
{
    const image = document.createElement('img');
    image.style.visibility = 'hidden';
    image.src = url;

    return new Promise(function(resolve, reject) {
        image.addEventListener('load', function() {
            resolve(image);
        });
        image.addEventListener('error', reject);
    });
}

class Upload
{
    constructor(props)
    {
        const self = this;

        this.id        = props.id;
        this.time      = new Date(props.time);
        this.author    = props.user_name;
        this.category  = props.category_name;
        this.mediaType = props.media_type;

        // List Entry:
        const categoryEl = document.createElement('span');
        categoryEl.innerHTML = this.category;

        const authorEl = document.createElement('span');
        authorEl.innerHTML = this.author;

        const listEntry = document.createElement('a');
        listEntry.classList.add('upload-entry');
        listEntry.appendChild(categoryEl);
        listEntry.appendChild(authorEl);
        listEntry.style.backgroundImage = "url('"+this.thumbnailUrl+"')";
        listEntry.href = '';
        listEntry.addEventListener('click', function(e) {
            setViewedUpload(self);
            e.preventDefault();
        });
        this.listEntry = listEntry;

        listEntry.classList.add('loading');
        loadImage(this.thumbnailUrl).then(function(image) {
            listEntry.classList.remove('loading');
        });
    }

    destroy()
    {
        this.listEntry.remove();
    }

    get url()
    {
        return '/upload/'+this.id;
    }

    get thumbnailUrl()
    {
        return '/upload/'+this.id+'/thumbnail';
    }
}


var uploadViewElement    = null;
var uploadImageElement   = null;
var uploadVideoElement   = null;
var uploadDetailsElement = null;
var uploadListElement    = null;

function prependUploadEntry(upload)
{
    const firstChild = uploadListElement.firstChild;
    uploadListElement.insertBefore(upload.listEntry, firstChild);
}

function clearViewedUpload(e)
{
    uploadImageElement.src = '';
    uploadVideoElement.src = '';

    uploadViewElement.removeEventListener('transitionend',    clearViewedUpload);
    uploadViewElement.removeEventListener('transitioncancel', clearViewedUpload);
}

function beginClearViewedUpload()
{
    uploadViewElement.classList.add('hidden');
    uploadViewElement.addEventListener('transitionend',    clearViewedUpload);
    uploadViewElement.addEventListener('transitioncancel', clearViewedUpload);
}

function setViewedUpload(upload)
{
    uploadViewElement.classList.remove('hidden');

    let visibleElement;
    let invisibleElement;
    let loadEventName;
    if(upload.mediaType === 'image')
    {
        visibleElement   = uploadImageElement;
        invisibleElement = uploadVideoElement;
        loadEventName = 'load';
    }
    else
    {
        visibleElement   = uploadVideoElement;
        invisibleElement = uploadImageElement;
        loadEventName = 'loadedmetadata';
    }

    invisibleElement.src = '';
    invisibleElement.style.display = 'none';

    visibleElement.src = upload.url;
    visibleElement.style.display = '';

    visibleElement.addEventListener(loadEventName, function() {
        let width, height;
        if(upload.mediaType === 'image')
        {
            width  = visibleElement.naturalWidth;
            height = visibleElement.naturalHeight;
        }
        else
        {
            width  = visibleElement.videoWidth;
            height = visibleElement.videoHeight;
        }
        visibleElement.style.maxWidth  = ''+width+'px';
        visibleElement.style.maxHeight = ''+height+'px';
    }, {once: true});
}

function getLatestUploads(count)
{
    const now = new Date(Date.now());
    const url = '/upload/query?limit='+count+'&order_asc=time&before='+now.toISOString();
    const request = new XMLHttpRequest();
    request.responseType = 'json';
    request.addEventListener('load', function(e)
    {
        if(request.responseType !== 'json')
            throw new Error('Invalid response type.');

        for(let uploadProps of request.response)
        {
            const upload = new Upload(uploadProps);
            prependUploadEntry(upload);
        }
    });
    request.open('GET', url);
    request.send();
}

window.addEventListener('load', function(e)
{
    uploadViewElement    = document.getElementById('upload-view');
    uploadImageElement   = document.getElementById('upload-image');
    uploadVideoElement   = document.getElementById('upload-video');
    uploadDetailsElement = document.getElementById('upload-details');
    uploadListElement    = document.getElementById('upload-list');

    getLatestUploads(100);

    const updatesEventSource = new EventSource('/updates');
    updatesEventSource.addEventListener('new-upload', function(e)
    {
        const message = JSON.parse(e.data);
        const upload = new Upload(message);
        prependUploadEntry(upload);
        setViewedUpload(upload);
    });

    uploadViewElement.addEventListener('click', function(e) {
        beginClearViewedUpload();
        e.preventDefault();
    });
    for(let childElement of uploadViewElement.childNodes)
    {
        childElement.addEventListener('click', function(e) {
            e.stopPropagation();
        });
    }
    window.addEventListener('keydown', function(e) {
        if(e.key === 'Escape')
        {
            beginClearViewedUpload();
            e.preventDefault();
        }
    });
});
