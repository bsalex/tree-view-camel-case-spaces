{CompositeDisposable} = require 'atom'
separateCamelCase = require './separate-camel-case'

module.exports = TreeViewCamelCaseSpaces =
  config:
    separator:
      type: 'string'
      default: '\u00B7'

  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.config.onDidChange 'tree-view-camel-case-spaces.separator', =>
      @treeView.updateRoots()

    atom.packages.activatePackage('tree-view').then (treeViewPkg) =>
      @treeView = treeViewPkg.mainModule.createView()
      @originalUpdateRoots = @treeView.updateRoots

      @treeView.updateRoots = (expansionStates={}) =>
        @originalUpdateRoots.call(@treeView, expansionStates)
        @traverseTree(@treeView.roots)

      @treeView.updateRoots()

  traverseTree: (entries) ->
    Array.from(entries).forEach((entry) =>
      @updateEntryName(entry)

      if entry.expand != undefined
        originalExpand = entry.expand
        originalCollapse = entry.collapse

        entry.expand = (isRecursive) =>
          result = originalExpand.call(entry, isRecursive)
          @addDirectorySubscriptions(entry)
          @traverseTree(entry.entries.childNodes)
          result

        entry.collapse = (isRecursive) =>
          @disposeDirectorySubscriptions(entry)
          originalCollapse.call(entry, isRecursive)

        @traverseTree(entry.entries.childNodes)
    )

  addDirectorySubscriptions: (directory) ->
    directory.treeViewCamelCaseSpacesSubscriptions = new CompositeDisposable
    directory.treeViewCamelCaseSpacesSubscriptions.add directory.directory.onDidAddEntries () =>
      @updateEntryName(directory)

    directory.treeViewCamelCaseSpacesSubscriptions.add directory.directory.onDidRemoveEntries () =>
      @updateEntryName(directory)

  disposeDirectorySubscriptions: (directory) ->
    if directory.treeViewCamelCaseSpacesSubscriptions
      directory.treeViewCamelCaseSpacesSubscriptions.dispose()

  getEntryOriginalName: (nameElement) ->
    nameElement.dataset.name || nameElement.parentNode.dataset.name

  updateEntryName: (list) ->
    element = list.querySelector(':scope > .header > .name, :scope > .name')
    element.textContent = separateCamelCase(
      @getEntryOriginalName(element),
      atom.config.get('tree-view-camel-case-spaces.separator')
    )

  deactivate: ->
    @disposables.dispose()
    @treeView.updateRoots = @originalUpdateRoots
    @treeView.updateRoots()
