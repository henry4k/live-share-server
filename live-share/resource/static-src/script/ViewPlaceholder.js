export class ViewPlaceholder {
    constructor(element) {
        this.element = element;
        this.clearCallback = this.clear.bind(this);
        element.classList.add('hidden');
    }

    set(imageUrl, width, height) {
        console.log('setUploadPlaceholder');
        const element = this.element;
        element.src = imageUrl;
        element.style.width  = ''+width+'px';
        element.style.height = ''+height+'px';
        element.classList.remove('hidden');
    }

    clear() {
        console.log('clearUploadPlaceholder');
        const element = this.element;
        element.src = '';
        element.style.width  = '';
        element.style.height = '';
        element.classList.add('hidden');
        element.removeEventListener('transitionend', this.clearCallback);
    }

    beginClear() {
        console.log('beginClearUploadPlaceholder');
        const element = this.element;
        element.classList.add('hidden');
        element.addEventListener('transitionend', this.clearCallback);
    }
}
