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

class LoadingManager {
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
    constructor(element) {
        this.element = element;
    }

    set size(size) {
        this.element.style.height = `${size}px`;
    }
}

export class InfiniScroll {
    constructor(startPlaceholderElement,
                entryContainerElement,
                endPlaceholderElement) {

        this.startPlaceholder = new Placeholder(startPlaceholderElement);
        // Occupies the space of unloaded entries.

        this.entryContainerElement = entryContainerElement;
        // Contains the loaded entries.

        this.endPlaceholder = new Placeholder(endPlaceholderElement);
        // Occupies the space between the last loaded entry and the page bottom.

        // TEST:
        this.endPlaceholder.size = 100;
    }
}
