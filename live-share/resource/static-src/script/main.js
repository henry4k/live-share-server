import { Upload } from './Upload';
import { init as initGrid, insertEntryAtFront } from './grid';
import { init as initView, setViewedUpload } from './view';
import { observableFromEventSource } from './utils';

window.addEventListener('load', function(e) {
    initGrid();
    initView();

    const updatesEventSource = new EventSource('/updates');
    const uploadStream = observableFromEventSource(updatesEventSource, 'new-upload')
        .map(data => JSON.parse(data))
        .map(uploadProps => new Upload(uploadProps))
        .subscribe(function(upload) {
            upload.listEntry.classList.add('new');
            insertEntryAtFront(upload);
            setViewedUpload(upload);
        });
});
