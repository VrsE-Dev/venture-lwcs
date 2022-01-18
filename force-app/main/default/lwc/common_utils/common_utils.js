import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export function parseRecord(data) {
    const object = {};
    
    Object.keys(data.fields).map((v) => {
        object[v] = data.fields[v].value;
    });

    return object;
}

export function showToast(variant, message) {
    const toast = new ShowToastEvent({
        title: variant.charAt(0).toUpperCase() + variant.slice(1),
        message,
        variant
    });

    return toast;
}