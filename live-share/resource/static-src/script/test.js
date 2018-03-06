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

async function requestEntries(referenceEntry,
                              before, // else: after
                              limit,
                              offset) {
    const result = [];
    for(let i = 0; i < limit; i++) {
        const entry = new Entry();
        entry.image = 'https://dummyimage.com/160x160&text='+i;
        entry.category = 'category '+i;
        entry.author = 'author '+i;
        result.push(entry.element);
    }
    return new Promise(function(resolve, reject) {
        window.setTimeout(function() {
            resolve(result);
        }, 1000);
    });
} // returns List<Element>

function createEntryPlaceholderElement() {
    const entry = document.createElement('a');
    entry.classList.add('upload-entry');
    entry.href = '';
    return entry;
}

export function test() {
    const uploadList = document.getElementById('upload-list');
    const infiniScroll = new InfiniScroll({
        element: uploadList,
        scrollElement: document.documentElement,
        scrollEventSource: window,
        requestEntryElements: requestEntries,
        createEntryPlaceholderElement: createEntryPlaceholderElement
    });
}
