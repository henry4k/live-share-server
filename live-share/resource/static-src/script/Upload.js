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

export class Upload
{
    constructor(props)
    {
        this.id        = props.id;
        this.time      = new Date(props.time);
        this.author    = props.user_name;
        this.category  = props.category_name;
        this.mediaType = props.media_type;
        this.width     = props.width;
        this.height    = props.height;

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
        //listEntry.addEventListener('click', function(e) {
        //    setViewedUpload(self); // TODO
        //    e.preventDefault();
        //});
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
