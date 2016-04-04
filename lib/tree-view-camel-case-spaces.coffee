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
      @updateNamesForRoots @treeView.list

    atom.packages.activatePackage('tree-view').then (treeViewPkg) =>
      @treeView = treeViewPkg.mainModule.createView()
      @originalUpdateRoots = @treeView.updateRoots
      @originalCollapseDirectory = @treeView.collapseDirectory
      @originalOpenSelectedEntry = @treeView.openSelectedEntry

      @treeView.updateRoots = (expansionStates={}) =>
        @originalUpdateRoots.call(@treeView, expansionStates)
        @updateNamesForRoots @treeView.list

      @treeView.openSelectedEntry = (options={}, expandDirectory=false) =>
        selectedEntry = @treeView.selectedEntry()

        if selectedEntry.directory
          @originalOpenSelectedEntry.call(@treeView, options, expandDirectory)
          @updateNames(selectedEntry)

          if selectedEntry.isExpanded
            @addDirectorySubscriptions(selectedEntry)
          else
            @disposeDirectorySubscriptions(selectedEntry)

        else
          @originalOpenSelectedEntry.call(@treeView, options, expandDirectory)

      @treeView.collapseDirectory = (isRecursive=false) =>
        selectedEntry = @treeView.selectedEntry()
        @originalCollapseDirectory.call(@treeView, isRecursive)
        @disposeDirectorySubscriptions(selectedEntry)

      @treeView.updateRoots()

  addDirectorySubscriptions: (directory) ->
    directory.treeViewCamelCaseSpacesSubscriptions = new CompositeDisposable
    directory.treeViewCamelCaseSpacesSubscriptions.add directory.directory.onDidAddEntries () =>
      @updateNames(directory)

    directory.treeViewCamelCaseSpacesSubscriptions.add directory.directory.onDidRemoveEntries () =>
      @updateNames(directory)

  disposeDirectorySubscriptions: (directory) ->
    if directory.treeViewCamelCaseSpacesSubscriptions
      directory.treeViewCamelCaseSpacesSubscriptions.dispose()

  updateNamesForRoots: (roots) ->
    Array.from(roots).forEach (root) =>
      @updateNames(root)
      directories = Array.from(root.querySelectorAll('[is="tree-view-directory"]'))
      directories.forEach (directory) =>
        @disposeDirectorySubscriptions(directory)
        @addDirectorySubscriptions(directory)

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
    @treeView.openSelectedEntry = @originalOpenSelectedEntry
    @treeView.updateRoots = @originalUpdateRoots
    @treeView.updateRoots()
