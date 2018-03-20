export class MediaView
{
    constructor(element, readyFn)
    {
        this.element = element;
        this.readyFn = readyFn;
    }

    set(sourceUrl, width, height)
    {
        console.log('MediaView.set');

        this.element.src = sourceUrl;
        this.element.style.maxWidth  = ''+width+'px';
        this.element.style.maxHeight = ''+height+'px';
        this.show();

        this._setupReadyEvent();
    }

    reset()
    {
        this._cancelReadyEvent();

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
    constructor()
    {
        super(...arguments);
    }

    _setupReadyEvent()
    {
        console.log(this);
        if(this.element.complete)
            this.readyFn();
        else
            this.element.addEventListener('load', this.readyFn);
    }

    _cancelReadyEvent()
    {
        this.element.removeEventListener('load', this.readyFn);
    }
}

export class VideoView extends MediaView
{
    constructor()
    {
        super(...arguments);
    }

    _setupReadyEvent()
    {
        console.log('VideoView._setupReadyEvent not implemented');
    }

    _cancelReadyEvent()
    {
        console.log('VideoView._cancelReadyEvent not implemented');
    }
}
