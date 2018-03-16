import { Observable, ReplaySubject } from 'rxjs';
import { fromJS } from 'immutable';


export function createStore(initialState) {
    return new ReplaySubject(1)
        .scan((state, changeFn) => fromJS(changeFn(state)),
              fromJS(initialState));
}

export function assert(v, msg) {
    if(v)
        return v;
    else
        throw new Error(msg || 'assertion failed');
}

export function promiseFromRequest(request) {
    return new Promise(function(resolve, reject) {
        request.addEventListener('error', e => reject(e.error));
        request.addEventListener('load', () => resolve(request.response));
    });
}

export function promiseFromObservable(observable) {
    observable = observable.first();
    //return new Promise(observable.subscribe);
    return new Promise(observable.subscribe.bind(observable));
    //return new Promise(function(resolve, reject) {
    //    observable.subscribe(resolve, reject);
    //});
}

export function observableFromEventSource(eventSource, eventName) {
    return Observable.create(function(observable) { // subscribe callback
        const eventFn = e => observable.next(e.data);
        const errorFn = e => observable.error(e);
        eventSource.addEventListener(eventName, eventFn);
        eventSource.addEventListener('error', errorFn);
        return function() { // unsubscribe callback
            eventSource.removeEventListener(eventName, eventFn);
            eventSource.removeEventListener('error', errorFn);
        };
    });
}
