import { Observable } from 'rxjs';
import { Upload } from './Upload';
import { init as initGrid } from './grid.js';
//import { init as initView } from './view.js';

window.addEventListener('load', function(e) {
    initGrid();
    //initView();

    //const updatesEventSource = new EventSource('/updates');
    //const uploadStream = Observable.fromEvent(updatesEventSource, 'new-upload')
    //    .map(event => JSON.parse(e.data))
    //    .map(uploadProps => new Upload(uploadProps));
    //    .subscribe(function(e) {
    //        prependUploadEntry(upload);
    //        setViewedUpload(upload);
    //    });
});
