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
