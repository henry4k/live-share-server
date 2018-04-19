export class MediaView
{
    constructor(element, readyCallbackUser)
    {
        this.element = element;
        this.readyCallbackUser = readyCallbackUser;
        this.readyCallback = this.onReady.bind(this);

        this.disable();
        this.hide();
    }

    set(sourceUrl, width, height)
    {
        console.log('MediaView.set');

        this.element.src = sourceUrl;
        this.element.style.maxWidth  = ''+width+'px';
        this.element.style.maxHeight = ''+height+'px';

        this.enable();
        this._setupReadyEvent();
    }

    onReady()
    {
        this.show();
        this.readyCallbackUser();
    }

    reset()
    {
        this._cancelReadyEvent();

        this.disable();
        this.hide();
        this.element.src = '';
        this.element.style.maxWidth  = '';
        this.element.style.maxHeight = '';
    }

    enable()
    {
        this.element.classList.remove('disabled');
    }

    disable()
    {
        this.element.classList.add('disabled');
    }

    show()
    {
        this.element.classList.remove('hidden');
    }

    hide()
    {
        this.element.classList.add('hidden');
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
        //this.timeout = window.setTimeout(this.readyCallback, 100);
        if(this.element.complete)
            this.readyCallback();
        else
            this.element.addEventListener('load', this.readyCallback);
    }

    _cancelReadyEvent()
    {
        //window.clearTimeout(this.timeout);
        this.element.removeEventListener('load', this.readyCallback);
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
