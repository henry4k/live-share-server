// TODO: Filename is temporary.

function getVisibleElementHeight(element) {
    const rect = element.getBoundingClientRect();
    const visibleTop = Math.max(rect.top, 0);
    const rectBottom = rect.top + rect.height;
    const visibleBottom = Math.min(rectBottom, window.innerHeight);
    return Math.max(0, visibleBottom-visibleTop);
}

// ............

export class InfiniScroll {
    constructor(options) {
        this.element = options.element;
        this.requestEntries = options.requestEntries;
        this.createEntryPlaceholderElement = options.createEntryPlaceholderElement;
        this.scrollElement = options.scrollElement || this.element;
        this.scrollEventSource = options.scrollEventSource || this.scrollElement;

        this.verticalPlaceholder = document.createElement('div');
        this.verticalPlaceholder.classList.add('placeholder');
        this.element.appendChild(this.verticalPlaceholder);
        // Occupies the space of unloaded entries.

        this.entryContainer = document.createElement('div');
        this.entryContainer.classList.add('loaded-entries');
        this.element.appendChild(this.entryContainer);
        // Contains the loaded entries.

        let timeoutId = null;
        this.scrollEventCallback = function() {
            if(!timeoutId) {
                timeoutId = window.setTimeout(function() {
                    timeoutId = null;
                    this.update();
                }.bind(this), 400);
            }
        }.bind(this);
        this.scrollEventSource.addEventListener('scroll', this.scrollEventCallback);

        this.update();
    }

    destroy() {
        this.scrollEventSource.removeEventListener(this.scrollEventCallback);
        this.verticalPlaceholder.remove();
        this.entryContainer.remove();
    }

    async update() {
        // TODO: Distance from .element to .scrollElement?
        console.log('update');

        const scrollTop = this.scrollElement.scrollTop;
        const scrollBottom = scrollTop + this.scrollElement.clientHeight;
        const scrollHeight = this.scrollElement.scrollHeight;

        const distanceToTop = scrollTop;
        const distanceToBottom = scrollHeight - scrollBottom;

        console.log(`top: ${distanceToTop}  bottom: ${distanceToBottom}`);

        if(distanceToBottom <= 500) { // TODO: Make configuratable
            const count = 20;
            const placeholders = [];
            for(let i = 0; i < count; i++) {
                placeholders.push(this.createEntryPlaceholderElement());
            }
            this.appendBack(placeholders);

            const entries = await this.requestEntries(undefined, false, count, 0);
            for(let i = 0; i < count; i++) {
                this.entryContainer.replaceChild(entries[i].element,
                                                 placeholders[i]);
            }
        }

        /*
        if(distanceToBottom <= 0) { // TODO: Make configuratable
            const count = 10;
            const placeholders = [];
            for(let i = 0; i < count; i++) {
                placeholders.push(this.createEntryPlaceholderElement());
            }
            this.appendBack(placeholders);
        }
        */
    }

    setVerticalPlaceholderSize(size) {
        this.verticalPlaceholder.style.height = `${size}px`;
    }

    appendFront(entries) {
        const container = this.entryContainer;
        entries.forEach(entry => {
            container.insertBefore(entry, container.firstChild);
        });
    }

    appendBack(entries) {
        const container = this.entryContainer;
        entries.forEach(entry => {
            container.appendChild(entry);
        });
    }

    removeFront(count) {
        const container = this.entryContainer;
        if(count > container.childNodes.length) {
            throw new Error('Container has not this many entries.');
        }
        for(let i = 0; i < count; i++) {
            container.removeChild(container.firstChild);
        }
    }

    removeBack(count) {
        const container = this.entryContainer;
        if(count > container.childNodes.length) {
            throw new Error('Container has not this many entries.');
        }
        for(let i = 0; i < count; i++) {
            container.removeChild(container.lastChild);
        }
    }
}
