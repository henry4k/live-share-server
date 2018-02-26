export class MediaView
{
    constructor(element)
    {
        this.element = element;
        this.eventTarget = new EventTarget();
    }

    addEventListener()
    {
        this.eventTarget.addEventListener(...arguments);
    }

    removeEventListener()
    {
        this.eventTarget.removeEventListener(...arguments);
    }

    set(sourceUrl, width, height)
    {
        this._setupReadyEvent();

        this.element.src = sourceUrl;
        this.element.style.maxWidth  = ''+width+'px';
        this.element.style.maxHeight = ''+height+'px';
        this.show();
    }

    reset()
    {
        //this._cancelReadyEvent(); // HMMMM!

        this.hide();
        this.element.src = '';
        this.element.style.maxWidth  = '';
        this.element.style.maxHeight = '';
    }

    show()
    {
        this.element.style.display = '';
    }

    hide()
    {
        this.element.style.display = 'none';
    }
}

export class ImageView extends MediaView
{
    constructor(element)
    {
        super(element);
    }

    _setupReadyEvent()
    {
        //this.element.addEventListener('load', )
    }
}

export class VideoView extends MediaView
{
    constructor(element)
    {
        super(element);
    }
}
