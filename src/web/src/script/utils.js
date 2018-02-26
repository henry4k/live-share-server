import { Observable, ReplaySubject } from 'rxjs';
import { fromJS } from 'immutable';


export function createStore(initialState) {
    return new ReplaySubject(1)
        .scan((state, changeFn) => fromJS(changeFn(state)),
              fromJS(initialState));
}
