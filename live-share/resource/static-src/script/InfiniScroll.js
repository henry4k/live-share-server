import { measure, mutate } from './fastdom-promised';
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
        this._requestEntries     = assert(o.requestEntries);
        this.createPlaceholder   = assert(o.createPlaceholder);
        this._replacePlaceholder = assert(o.replacePlaceholder);
        this.pushElement         = assert(o.pushElement);
        this.removeElement       = assert(o.removeElement);

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

    // This can be used to manually add entries.
    insertEntry(entry) {
        const el = this.createPlaceholder();
        this.pushElement(el); // TODO: Also a ghetto solution. :/
        this._replacePlaceholder(el, entry);
        this.firstEntry = entry;
    }

    replacePlaceholder(entry) {
        const placeholder = this.placeholders.shift();
        this._replacePlaceholder(placeholder, entry);
        this.firstEntry = entry;
    }

    end() {
        this.ended = true;
        this.requestedEntryCount = 0;
        console.log('stream ended');
    }

    async runRequest() {
        try {
            while(!this.ended && this.requestedEntryCount > 0) {
                const requestedEntryCount = this.requestedEntryCount;
                const entries =
                    await this._requestEntries(this.firstEntry, requestedEntryCount);
                entries.forEach(this.replacePlaceholder.bind(this));
                if(entries.length < requestedEntryCount)
                    this.end();
            }
        } finally {
            this.requestRunning = false;
        }
    }

    requestEntries(count) {
        if(this.ended)
            return;

        this.requestedEntryCount += count;

        if(this.requestRunning)
            return;

        this.requestRunning = true;
        this.runRequest();
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

        const frontContainer = document.createElement('div');
        frontContainer.classList.add('loaded-entries');
        frontContainer.classList.add('front');
        this.frontElementContainer = frontContainer;

        const backContainer = document.createElement('div');
        backContainer.classList.add('loaded-entries');
        backContainer.classList.add('back');
        this.backElementContainer = backContainer;

        this.element.appendChild(frontContainer);
        this.element.appendChild(backContainer);

        this.bufferDistance = 500; // in pixels
        // Minimum distance to scrollElement top and bottom.

        this.minRequestCount = 10;

        const minUpdateRate = 400; // in milliseconds

        const requestEntries = o.requestEntries;

        this.frontEntryStream = new EntryStreamSide({
            requestEntries: function(referenceEntry, count) {
                return requestEntries(referenceEntry, 'after', count);
            },
            createPlaceholder: o.createEntryPlaceholderElement,
            replacePlaceholder: o.replacePlaceholder,
            pushElement: function(element) {
                frontContainer.appendChild(element);
            }.bind(this),
            removeElement: function(element) {
                frontContainer.removeChild(element);
            }.bind(this)
        });
        this.backEntryStream = new EntryStreamSide({
            requestEntries: function(referenceEntry, count) {
                return requestEntries(referenceEntry, 'before', count);
            },
            createPlaceholder: o.createEntryPlaceholderElement,
            replacePlaceholder: o.replacePlaceholder,
            pushElement: function(element) {
                backContainer.appendChild(element);
                //container.insertBefore(element, container.firstChild);
            }.bind(this),
            removeElement: function(element) {
                backContainer.removeChild(element);
            }.bind(this)
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
        this.element.removeChild(this.frontElementContainer);
        this.element.removeChild(this.backElementContainer);
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
            await measure(() => true); // just wait for next measurement point
            console.log(`buffer: ${this.distanceToBottom}px`);
        }
    }

    // This can be used to manually add entries.
    insertEntryAtFront(entry) {
        this.frontEntryStream.insertEntry(entry);
    }
}
