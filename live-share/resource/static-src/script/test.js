import { InfiniScroll } from './InfiniScroll';

class Entry {
    constructor() {
        const categoryEl = document.createElement('span');
        const authorEl = document.createElement('span');
        const el = document.createElement('a');
        el.classList.add('upload-entry');
        el.appendChild(categoryEl);
        el.appendChild(authorEl);
        el.href = '';

        this.element = el;
        this.categoryElement = categoryEl;
        this.authorElement = authorEl;
    }

    set thumbnailImage(url) {
        this.element.style.backgroundImage = "url('"+url+"')";
    }

    set category(text) {
        this.categoryElement.innerHTML = text;
    }

    set author(text) {
        this.authorElement.innerHTML = text;
    }
}

let beforeCounter = 1;
let afterCounter  = 1;

async function requestEntries(referenceEntry,
                              direction,
                              count) {
    const result = [];
    for(let i = 0; i < count; i++) {
        let id;
        if(direction === 'before') {
            id = -(beforeCounter++);
        } else {
            id = afterCounter++;
        }

        const entry = new Entry();
        entry.thumbnailImage = 'https://dummyimage.com/160x160&text='+id;
        entry.category = direction;
        entry.author = ''+(i+1)+'. in batch';
        result.push(entry);
    }
    return new Promise(function(resolve, reject) {
        window.setTimeout(function() {
            resolve(result);
        }, 1000);
    });
} // returns List<Element>

function createEntryPlaceholderElement() {
    const element = document.createElement('a');
    element.classList.add('upload-entry');
    element.href = '';
    return element;
}

function replacePlaceholder(placeholder, entry) {
    // Ghetto implementation:
    const parent = placeholder.parentElement;
    parent.replaceChild(entry.element, placeholder);
}

export function test() {
    const uploadList = document.getElementById('upload-list');
    const infiniScroll = new InfiniScroll({
        element: uploadList,
        scrollElement: document.documentElement,
        scrollEventSource: window,
        requestEntries: requestEntries,
        createEntryPlaceholderElement: createEntryPlaceholderElement,
        replacePlaceholder: replacePlaceholder
    });
}
