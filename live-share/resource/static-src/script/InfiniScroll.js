// TODO: Filename is temporary.
import { assert } from './utils';

class EntryStreamSide {
    /**
     * @param {Object} o Options
     * @param {Function} o.requestEntries
     * Expects a function taking (referenceEntry, count) and returning a
     * promise for entries.
     * @param {Function} o.createPlaceholder
     * @param {Function} o.replacePlaceholder
     * @param {Function} o.pushElement
     * @param {Function} o.removeElement
     */
    constructor(o) {
        this._requestEntries    = assert(o.requestEntries);
        this.createPlaceholder  = assert(o.createPlaceholder);
        this.replacePlaceholder = assert(o.replacePlaceholder);
        this.pushElement        = assert(o.pushElement);
        this.removeElement      = assert(o.removeElement);

        this.ended = false; // no more entries available
        this.firstEntry = null;
        this.requestRunning = false;
        this.placeholders = [];
    }

    get requestedEntryCount() {
        return this.placeholders.length;
    }

    set requestedEntryCount(count) {
        const placeholders = this.placeholders;
        const diff = count - placeholders.length;
        if(diff > 0)
            for(let i = 0; i < diff; i++) {
                const p = this.createPlaceholder();
                this.pushElement(p);
                placeholders.push(p);
            }
        else
            for(let i = 0; i < -diff; i++)
                this.removeElement(placeholders.pop());
        assert(placeholders.length === count);
    }

    insertEntry(entry) {
        const placeholder = this.placeholders.shift();
        this.replacePlaceholder(placeholder, entry);
        this.firstEntry = entry;
    }

    end() {
        this.ended = true;
        this.requestedEntryCount = 0;
        console.log('stream ended');
    }

    async requestEntries(count) {
        if(this.ended)
            return;

        this.requestedEntryCount += count;

        if(this.requestRunning)
            return;

        this.requestRunning = true;
        try {
            while(!this.ended && this.requestedEntryCount > 0) {
                const requestedEntryCount = this.requestedEntryCount;
                const entries =
                    await this._requestEntries(this.firstEntry, requestedEntryCount);
                entries.forEach(this.insertEntry.bind(this));
                if(entries.length < requestedEntryCount)
                    this.end();
            }
        } finally {
            this.requestRunning = false;
        }
    }
}

/**
 * @param {Object} o Options
 * @param {Element} o.element
 * @param {Function} o.requestEntries
 * Expects a function taking (referenceEntry, direction, count) and returning
 * a promise for entries.
 * @param {Function} o.createEntryPlaceholderElement
 * @param {Function} o.replacePlaceholder
 * Expects a function taking (placeholder, entry).
 * @param {Element} [o.scrollElement]
 * @param {EventSource} [o.scrollEventSource]
 */
export class InfiniScroll {
    constructor(o) {
        this.element           = assert(o.element);
        this.scrollElement     = assert(o.scrollElement     || this.element);
        this.scrollEventSource = assert(o.scrollEventSource || this.scrollElement);
        assert(o.requestEntries);
        assert(o.createEntryPlaceholderElement);
        assert(o.replacePlaceholder);

        this.entryContainer = document.createElement('div');
        this.entryContainer.classList.add('loaded-entries');
        this.element.appendChild(this.entryContainer);
        // Contains the loaded entries.

        this.bufferDistance = 500; // in pixels
        // Minimum distance to scrollElement top and bottom.

        this.minRequestCount = 10;

        const minUpdateRate = 400; // in milliseconds

        const requestEntries = o.requestEntries;
        const removeElement = function(element) {
            this.entryContainer.removeChild(element);
        }.bind(this);

        this.frontEntryStream = new EntryStreamSide({
            requestEntries: function(referenceEntry, count) {
                return requestEntries(referenceEntry, 'after', count);
            },
            createPlaceholder: o.createEntryPlaceholderElement,
            replacePlaceholder: o.replacePlaceholder,
            pushElement: function(element) {
                const container = this.entryContainer;
                container.insertBefore(element, container.firstChild);
            }.bind(this),
            removeElement: removeElement
        });
        this.backEntryStream = new EntryStreamSide({
            requestEntries: function(referenceEntry, count) {
                return requestEntries(referenceEntry, 'before', count);
            },
            createPlaceholder: o.createEntryPlaceholderElement,
            replacePlaceholder: o.replacePlaceholder,
            pushElement: function(element) {
                this.entryContainer.appendChild(element);
            }.bind(this),
            removeElement: removeElement
        });

        let timeoutId = null;
        this.scrollEventCallback = function() {
            if(!timeoutId) {
                timeoutId = window.setTimeout(function() {
                    timeoutId = null;
                    this.update();
                }.bind(this), minUpdateRate);
            }
        }.bind(this);
        this.scrollEventSource.addEventListener('scroll', this.scrollEventCallback);

        this.update();
    }

    destroy() {
        this.scrollEventSource.removeEventListener(this.scrollEventCallback);
        this.entryContainer.remove();
    }

    get distanceToTop() {
        // TODO: Distance from .element to .scrollElement?
        return this.scrollElement.scrollTop;
    }

    get distanceToBottom() {
        const scrollElement = this.scrollElement;
        const scrollTop = scrollElement.scrollTop;
        const scrollBottom = scrollTop + scrollElement.clientHeight;
        const scrollHeight = scrollElement.scrollHeight;
        return scrollHeight - scrollBottom;
    }

    async update() {
        const frontStream = this.frontEntryStream;
        const backStream = this.backEntryStream;
        const bufferDistance = this.bufferDistance;
        const count = this.minRequestCount;

        //while(!frontStream.ended && this.distanceToTop <= bufferDistance) {
        //    frontStream.requestEntries(count);
        //}

        while(!backStream.ended && this.distanceToBottom <= bufferDistance) {
            console.log('backEntryStream: request entries');
            backStream.requestEntries(count);
            console.log(`buffer: ${this.distanceToBottom}px`);
        }
    }
}
