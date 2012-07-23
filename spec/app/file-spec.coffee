File = require 'file'
fs = require 'fs'

describe 'File', ->
  [path, file] = []

  beforeEach ->
    path = fs.join(require.resolve('fixtures'), "atom-file-test.txt") # Don't put in /tmp because /tmp symlinks to /private/tmp and screws up the rename test
    fs.remove(path) if fs.exists(path)
    fs.write(path, "this is old!")
    file = new File(path)

  afterEach ->
    file.off()
    fs.remove(path) if fs.exists(path)

  describe "when the contents of the file change", ->
    it "triggers 'contents-change' event handlers", ->
      changeHandler = null
      changeHandler = jasmine.createSpy('changeHandler')
      file.on 'contents-change', changeHandler
      fs.write(file.getPath(), "this is new!")

      waitsFor "change event", ->
        changeHandler.callCount > 0

      runs ->
        changeHandler.reset()
        fs.write(file.getPath(), "this is newer!")

      waitsFor "second change event", ->
        changeHandler.callCount > 0

  describe "when a file is moved (via the filesystem)", ->
    newPath = null

    beforeEach ->
      newPath = fs.join(fs.directory(path), "atom-file-was-moved-test.txt")

    afterEach ->
      fs.remove(newPath) if fs.exists(newPath)

    it "it updates its path", ->
      moveHandler = null
      moveHandler = jasmine.createSpy('moveHandler')
      file.on 'move', moveHandler

      fs.move(path, newPath)

      waitsFor "move event", ->
        moveHandler.callCount > 0

      runs ->
        expect(file.getPath()).toBe newPath

    it "maintains 'contents-change' events set on previous path", ->
      moveHandler = null
      moveHandler = jasmine.createSpy('moveHandler')
      file.on 'move', moveHandler
      changeHandler = null
      changeHandler = jasmine.createSpy('changeHandler')
      file.on 'contents-change', changeHandler

      fs.move(path, newPath)

      waitsFor "move event", ->
        moveHandler.callCount > 0

      runs ->
        expect(changeHandler).not.toHaveBeenCalled()
        fs.write(file.getPath(), "this is new!")

      waitsFor "change event", ->
        changeHandler.callCount > 0

