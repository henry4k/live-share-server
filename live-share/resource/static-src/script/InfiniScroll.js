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
            for(let i = 0; i < diff; i++)
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
    }

    async requestEntries(count) {
        if(this.ended)
            return;

        this.requestedEntryCount += count;

        if(this.requestRunning)
            return;

        this.requestRunning = true;
        try {
            const requestedEntryCount = this.requestedEntryCount;
            const entries =
                await this._requestEntries(this.firstEntry, requestedEntryCount);
            entries.forEach(this.insertEntry.bind(this));
            if(entries.length < requestedEntryCount)
                end();
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

        const requestEntries = o.requestEntries;
        const removeElement = function(element) {
            this.entryContainer.removeChild(element);
        }.bind(this);

        this.frontEntryStream = new EntryStreamSide({
            requestEntries: function(referenceEntry, count) {
                return requestEntries(referenceEntry, 'before', count);
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
                return requestEntries(referenceEntry, 'after', count);
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
                }.bind(this), 400);
            }
        }.bind(this);
        this.scrollEventSource.addEventListener('scroll', this.scrollEventCallback);

        this.update();
    }

    destroy() {
        this.scrollEventSource.removeEventListener(this.scrollEventCallback);
        this.entryContainer.remove();
    }

    async update() {
        // TODO: Distance from .element to .scrollElement?

        const scrollTop = this.scrollElement.scrollTop;
        const scrollBottom = scrollTop + this.scrollElement.clientHeight;
        const scrollHeight = this.scrollElement.scrollHeight;

        const distanceToTop = scrollTop;
        const distanceToBottom = scrollHeight - scrollBottom;

        if(distanceToTop <= 500) // TODO: Make configuratable
            this.frontEntryStream.requestEntries(10);
        if(distanceToBottom <= 500) // TODO: Make configuratable
            this.backEntryStream.requestEntries(10);
    }
}
