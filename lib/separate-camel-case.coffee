module.exports = (name, separator) ->
  name.match(/(?:[A-Z]+|^)[^A-Z]*/g).join(separator)
