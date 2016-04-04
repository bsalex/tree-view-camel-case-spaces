{CompositeDisposable} = require 'atom'
separateCamelCase = require './separate-camel-case'

module.exports = TreeViewCamelCaseSpaces =
  config:
    separator:
      type: 'string'
      default: '\u00B7'

  initialize: () ->
    @disposables = new CompositeDisposable
    @disposables.add atom.config.onDidChange 'tree-view-camel-case-spaces.separator', =>
      @updateNames(@treeView.list[0])

  activate: (state) ->
    atom.packages.activatePackage('tree-view').then (treeViewPkg) =>
      @treeView = treeViewPkg.mainModule.createView()
      @originalUpdateRoots = @treeView.updateRoots
      @originalOpenSelectedEntry = @treeView.openSelectedEntry

      @treeView.updateRoots = (expansionStates={}) =>
        @originalUpdateRoots.call(@treeView, expansionStates)
        @updateNames(@treeView.list[0])

      @treeView.openSelectedEntry = (options={}, expandDirectory=false) =>
        selectedEntry = @treeView.selectedEntry()
        if selectedEntry.expand
          @originalOpenSelectedEntry.call(@treeView, options, expandDirectory)
          @updateNames(selectedEntry)
        else
          @originalOpenSelectedEntry.call(@treeView, options, expandDirectory)

      @treeView.updateRoots()

  getEntryOriginalName: (nameElement) ->
    nameElement.dataset.name || nameElement.parentNode.dataset.name

  updateNames: (list) ->
    Array.from(
      list.querySelectorAll('.name')
    ).forEach (element) =>
      element.textContent = separateCamelCase(
        @getEntryOriginalName(element),
        atom.config.get('tree-view-camel-case-spaces.separator')
      )

  deactivate: ->
    @disposables.dispose()
    @treeView.updateRoots = @originalUpdateRoots
    @treeView.openSelectedEntry = @originalOpenSelectedEntry
    @treeView.updateRoots()
