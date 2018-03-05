// TODO: Filename is temporary.

class Range {
    constructor(start, end) {
        this.start = start;
        this.end   = end;
    }

    get length() {
        return this.end - this.start;
    }

    contains(other) {
        return this.start <= other.start &&
               this.end   >= other.end;
    }

    distanceTo(other) {
        return Math.max(this.start  - other.end,
                        other.start - this.end);
    }

    overlaps(other) {
        return this.distanceTo(other) < 0;
    }

    unionWith(other) {
        return new Range(Math.min(this.start, other.start),
                         Math.max(this.end,   other.end));
    }

    intersectionWith(other) {
        return new Range(Math.max(this.start, other.start),
                         Math.min(this.end,   other.end));
    }
}

class Advisor {
    constructor() {
        this.currentRange = new Range();
    }

    update(visibleRangeStart, visibleRangeEnd) {
        const visibleRange = new Range(visibleRangeStart,
                                       visibleRangeEnd);

        const requestedRange = visibleRange;
        // TODO: Think of a more elaborated algorithm.

        const result = {start: requestedRange.start - this.currentRange.start,
                        end:   requestedRange.end   - this.currentRange.end};
        // Positive values mean: Load n entries.
        // Negative values mean: Unload n entries.

        this.currentRange = requestedRange;

        return result;
    }
}

function getVisibleElementHeight(element) {
    const rect = element.getBoundingClientRect();
    const visibleTop = Math.max(rect.top, 0);
    const rectBottom = rect.top + rect.height;
    const visibleBottom = Math.min(rectBottom, window.innerHeight);
    return Math.max(0, visibleBottom-visibleTop);
}

class Placeholder {
    constructor() {
        const element = document.createElement('div');
        element.classList.add('placeholder');
        this.element = element;
    }

    destroy() {
        this.element.remove();
    }

    set size(size) {
        this.element.style.height = `${size}px`;
    }
}

export class InfiniScroll {
    constructor(options) {
        this.element = options.element;
        this.entryWidth  = options.entryWidth;
        this.entryHeight = options.entryWidth;

        this.placeholder = new Placeholder();
        this.element.appendChild(this.placeholder.element);
        // Occupies the space of unloaded entries.

        this.entryContainer = document.createElement('div');
        this.entryContainer.classList.add('loaded-entries');
        this.element.appendChild(this.entryContainer);
        // Contains the loaded entries.
    }

    destroy() {
        this.placeholder.destroy();
        this.entryContainer.remove();
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
