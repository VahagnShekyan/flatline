try {
    throw 'boom'
}
catch {
    'caught ' + $_.Exception.Message
}
finally {
    'done'
}
