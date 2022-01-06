export function parseRecord(data) {
    const object = {};
    
    Object.keys(data.fields).map((v) => {
        object[v] = data.fields[v].value;
    });

    return object;
}