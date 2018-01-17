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

        this.thumbnailSizePromise = loadImage(this.thumbnailUrl).then(function(image) {
            return [image.width, image.height];
        });

        // List Entry:
        const categoryEl = document.createElement('span');
        categoryEl.innerHTML = this.category;

        const authorEl = document.createElement('span');
        authorEl.innerHTML = this.author;

        const listEntry = document.createElement('a');
        listEntry.appendChild(categoryEl);
        listEntry.appendChild(authorEl);
        listEntry.style.backgroundImage = "url('"+this.thumbnailUrl+"')";
        listEntry.href = '';
        listEntry.addEventListener('click', function(e) {
            setViewedUpload(self);
            e.preventDefault();
        });
        this.listEntry = listEntry;
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

    async getBlurryImageUrl()
    {
        const self = this;
        return this.thumbnailSizePromise.then(function(size) {
            return '/upload/'+self.id+'/_blurry_thumbnail?width='+size[0]+'&height='+size[1];
        });
    }
}


var uploadViewElement = null;
var uploadImageElement = null;
var uploadVideoElement = null;
var uploadDetailsElement = null;
var uploadListElement = null;

function appendUploadEntry(upload)
{
    uploadListElement.appendChild(upload.listEntry);
}

function resetViewedUpload()
{
    uploadViewElement.style.backgroundImage = '';
    uploadImageElement.src = '';
    uploadVideoElement.src = '';
    uploadImageElement.style.display = 'none';
    uploadVideoElement.style.display = 'none';
}

async function setViewedUpload(upload)
{
    resetViewedUpload();

    //const blurryImageUrl = await upload.getBlurryImageUrl();
    //uploadViewElement.style.backgroundImage = "url('"+blurryImageUrl+"')";

    if(upload.mediaType == 'image')
    {
        uploadImageElement.src = upload.url;
        uploadImageElement.style.display = 'initial';
    }
    else
    {
        uploadVideoElement.src = upload.url;
        uploadVideoElement.style.display = 'initial';
    }
}

function getLatestUploads(count)
{
    const now = new Date(Date.now());
    const url = '/upload/query?limit='+count+'&order=time&before='+now.toISOString();
    const request = new XMLHttpRequest();
    request.responseType = 'json';
    request.addEventListener('load', function(e)
    {
        if(request.responseType !== 'json')
            throw new Error('Invalid response type.');

        for(let uploadProps of request.response)
        {
            const upload = new Upload(uploadProps);
            appendUploadEntry(upload);
        }
    });
    request.open('GET', url);
    request.send();
}

window.addEventListener('load', function(e)
{
    uploadViewElement = document.getElementById('upload-view');
    uploadImageElement = document.getElementById('upload-image');
    uploadVideoElement = document.getElementById('upload-video');
    uploadDetailsElement = document.getElementById('upload-details');
    uploadListElement = document.getElementById('upload-list');

    getLatestUploads(10);

    const updatesEventSource = new EventSource('/updates');
    updatesEventSource.addEventListener('new-upload', function(e)
    {
        const message = JSON.parse(e.data);
        const upload = new Upload(message);
        appendUploadEntry(upload);
        setViewedUpload(upload);
    });
});
