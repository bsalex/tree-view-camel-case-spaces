separateCamelCase = require '../lib/separate-camel-case'

describe "separateCamelCase", ->
  samples = [
    ['filename', 'filename']
    ['fileName', 'file-Name']
    ['FileName', 'File-Name']
    ['FIleName', 'FIle-Name']
    ['FiLeName', 'Fi-Le-Name']
  ]

  samples.forEach (sample) ->
    it "should transform \"${sample[0]}\" to \"${sample[1]}\"", ->
      expect(separateCamelCase(sample[0], '-')).toBe(sample[1])
