/*
  Copyright (C) 2015 Michal Kosciesza <michal@mkiol.net>

  This file is part of Kaktus.

  Kaktus is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Kaktus is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Kaktus.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    allowedOrientations: {
        switch (settings.allowedOrientations) {
        case 1:
            return Orientation.Portrait;
        case 2:
            return Orientation.Landscape;
        }
        return Orientation.Landscape | Orientation.Portrait;
    }

    property bool showBar: true
    property string title
    property bool landscapeMode: settings.doublePane && (app.isTablet || root.orientation === Orientation.Landscape)
    property EntryDelegate expandedDelegate
    property string expandedUid: ""
    property int expandedIndex: 0

    function navigate(url) {
        var hcolor = Theme.highlightColor.toString().substr(1, 6);
        var shcolor = Theme.secondaryHighlightColor.toString().substr(1, 6);
        var imgWidth = settings.fontSize == 1 ? root.width/(1.5) : settings.fontSize == 2 ? root.width/(2.0) : root.width;
        return url+"?fontsize=18px&width="+imgWidth+"&highlightColor="+hcolor+"&secondaryHighlightColor="+shcolor+"&margin="+Theme.paddingMedium;
    }

    function openInExaternalBrowser(index, link, uid) {
        entryModel.setData(index, "read", 1, "");
        notification.show(qsTr("Launching an external browser..."));
        Qt.openUrlExternally(settings.offlineMode ? navigate(cache.getUrlbyId(uid)) : link);
    }

    function setContentPane(delegate) {
        //console.log("setContentPane",delegate);
        contentPanel.index = delegate.index
        contentPanel.content = app.isTablet ? delegate.contentraw : delegate.contentall;
        contentPanel.image = app.isTablet ? "" : delegate.image;
        contentPanel.expanded = false;
        delegate.expanded = true;
        //listView.positionViewAtIndex(delegate.index, ListView.Visible);

        /*if (landscapeMode) {
            pageStack.pushAttached(Qt.resolvedUrl("WebPreviewPage.qml"),
                           {"entryId": delegate.uid,
                               "onlineUrl": delegate.onlineurl,
                               "offlineUrl": delegate.offlineurl,
                               "title": delegate.title,
                               "stared": delegate.readlater==1,
                               "index": delegate.index,
                               "feedindex": delegate.index,
                               "read" : delegate.read==1,
                               "cached" : delegate.cached
                           });
        }*/
    }

    function getDelegateByUid(uid) {
        for (var i = 0; i < listView.contentItem.children.length; i++) {
            curItem = listView.contentItem.children[i];
            if (curItem.objectName === "EntryDelegate" && !curItem.last && !curItem.daterow &&
                    curItem.uid === uid) {
                return curItem;
            }
        }
        return undefined;
    }

    function clearContentPane(delegate) {
        if (delegate) {
            if (contentPanel.index == delegate.index) {
                contentPanel.index = 0;
                contentPanel.content = "";
                contentPanel.image = "";
                contentPanel.expanded = false;
            }
        } else {
            contentPanel.index = 0;
            contentPanel.content = "";
            contentPanel.image = "";
            contentPanel.expanded = false;
        }

        /*if (landscapeMode) {
            pageStack.popAttached();
        }*/
    }

    function autoSetDelegate() {
        var delegate = root.expandedDelegate ? root.expandedDelegate : root.expandedUid!="" ? getDelegateByUid(root.expandedUid) : undefined;
        //console.log("autoSetDelegate",delegate);
        if (!delegate) {
            var curItem = listView.itemAt(0,listView.contentY + root.height/4);
            if (curItem.objectName === "EntryDelegate" && !curItem.last && !curItem.daterow) {
                curItem.expanded = true;
                //expandedDelegate = curItem;
                //expandedUid = curItem.uid;
                //expandedIndex = curItem.index;
                return;
            } else {
                for (var i = 0; i < listView.contentItem.children.length; i++) {
                    curItem = listView.contentItem.children[i];
                    if (curItem.objectName === "EntryDelegate" && !curItem.last && !curItem.daterow) {
                        curItem.expanded = true;
                        //expandedDelegate = curItem;
                        //expandedUid = curItem.uid;
                        //expandedIndex = curItem.index;
                        //listView.positionViewAtIndex(curItem.index, ListView.Contain);
                        return;
                    }
                }
            }
        }
    }

    /*onExpandedDelegateChanged: {
        if (expandedDelegate) {
            setContentPane(expandedDelegate);
        } else {
            clearContentPane(expandedDelegate);
        }
    }*/

    onExpandedUidChanged: {
        //console.log("onExpandedUidChanged",root.expandedUid, root.expandedDelegate, root.expandedIndex);
        var delegate = root.expandedDelegate ? root.expandedDelegate : root.expandedUid!="" ? getDelegateByUid(root.expandedUid) : undefined;
        //console.log("delegate",delegate);
        if (delegate) {
            setContentPane(delegate);
        } else {
            clearContentPane(delegate);
        }
    }

    /*Component.onCompleted: {
        console.log("Component.onCompleted",landscapeMode);
        if (landscapeMode)
            autoSetDelegate();
    }*/

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (landscapeMode)
                autoSetDelegate();
        }
    }

    onOrientationTransitionRunningChanged: {
        if (!orientationTransitionRunning) {
            //console.log("onOrientationTransitionRunningChanged");
            if (landscapeMode) {
                autoSetDelegate();
            } else {
                var delegate = root.expandedDelegate ? root.expandedDelegate : root.expandedUid!="" ? getDelegateByUid(root.expandedUid) : undefined;
                if (delegate)
                    listView.positionViewAtIndex(delegate.index, ListView.Contain);
            }
        }
    }

    ActiveDetector {
        onInit: { bar.flick = listView;}
    }

    RemorsePopup {id: remorse}

    SilicaListView {
        id: listView
        model: entryModel

        anchors { top: parent.top; left: parent.left; }
        //width: root.landscapeMode && contentPanel.active ? parent.width - app.landscapeContentPanelWidth : parent.width
        width: root.landscapeMode && listView.count != 0 ? parent.width - app.landscapeContentPanelWidth : parent.width

        clip: true

        height: app.flickHeight

        /*onMovingChanged: {
            if (root.landscapeMode && !moving) {
                var item = itemAt(0,contentY + root.height/3);
                if (!item.last && !item.daterow)
                    item.expanded = true;
            }
        }*/

        onContentYChanged: {
            if (root.landscapeMode) {
                var itemTop = itemAt(0,contentY + root.height/5);
                var itemBottom = itemAt(0,contentY + 4*root.height/5);
                if (!itemTop.last && !itemTop.daterow) {
                    if (root.expandedDelegate) {
                        if (root.expandedDelegate.index < itemTop.index ||
                            root.expandedDelegate.index > itemBottom.index  )
                            itemTop.expanded = true;
                        else
                            return;
                    } else {
                        itemTop.expanded = true;
                    }
                }
            }
        }

        PageMenu {
            id: menu
            showAbout: settings.viewMode>2  ? true : false
            showMarkAsRead: false
            showMarkAsUnread: false
            showShowOnlyUnread: settings.viewMode!=4 && settings.viewMode!=6 && settings.viewMode!=7

            onMarkedAsRead: {
                if (settings.viewMode==1 || settings.viewMode==5) {
                    remorse.execute(qsTr("Marking articles as read"), function(){entryModel.setAllAsRead()});
                    return;
                }
                if (settings.viewMode==3) {
                    remorse.execute(qsTr("Marking all your articles as read"), function(){entryModel.setAllAsRead()});
                    return;
                }
                if (settings.viewMode==4) {
                    remorse.execute(
                                settings.signinType<10 || settings.signinType>=20 ?
                                    qsTr("Marking all saved articles as read") :
                                    qsTr("Marking all starred articles as read")
                                , function(){entryModel.setAllAsRead()});
                    return;
                }
                if (settings.viewMode==6) {
                    remorse.execute(qsTr("Marking all liked articles as read"), function(){entryModel.setAllAsRead()});
                    return;
                }
                if (settings.viewMode==7) {
                    remorse.execute(qsTr("Marking all shared articles as read"), function(){entryModel.setAllAsRead()});
                    return;
                }

                entryModel.setAllAsRead();
            }

            /*onMarkedAsUnread:  {
                if (settings.viewMode==1 ||
                        settings.viewMode==3 ||
                        settings.viewMode==4 ||
                        settings.viewMode==5) {
                    pageStack.push(Qt.resolvedUrl("UnreadAllDialog.qml"),{"type": 2});
                } else {
                    entryModel.setAllAsUnread();
                }
            }*/

            onActiveChanged: {
                if (active) {
                    if (settings.viewMode!=4 && settings.viewMode!=6 && settings.viewMode!=7) {
                        showMarkAsRead = entryModel.countUnread()!=0;
                        /*if (!settings.showOnlyUnread)
                            showMarkAsUnread = entryModel.countRead()!=0;*/
                    }
                }
            }
        }

        header: PageHeader {
            title: {
                switch (settings.viewMode) {
                case 3:
                    return qsTr("All feeds");
                case 4:
                    return app.isNetvibes || app.isFeedly ? qsTr("Saved") : qsTr("Starred");
                case 5:
                    return qsTr("Slow");
                case 6:
                    return qsTr("Liked");
                case 7:
                    return qsTr("Shared");
                default:
                    return root.title;
                }
            }
        }

        delegate: EntryDelegate {
            id: delegate
            uid: model.uid
            title: model.title
            content: model.content
            contentall: model.contentall
            contentraw: model.contentraw
            date: model.date
            read: model.read
            friendStream: model.feedId.substring(0,4) === "user"
            feedIcon: model.feedIcon
            feedTitle: model.feedTitle
            author: model.author
            image: model.image
            readlater: model.readlater
            index: model.index
            cached: model.cached
            broadcast: model.broadcast
            liked: model.liked
            annotations: model.annotations
            fresh: model.fresh
            last: model.uid === "last"
            daterow: model.uid === "daterow"
            showMarkedAsRead: settings.viewMode!=4 && settings.viewMode!=6 && settings.viewMode!=7 && model.read<2
            objectName: "EntryDelegate"
            landscapeMode: root.landscapeMode
            onlineurl: model.link
            offlineurl: cache.getUrlbyId(model.uid)

            signal singleEntryClicked
            signal doubleEntryClicked

            function check() {
                // Not allowed while Syncing
                if (dm.busy || fetcher.busy || dm.removerBusy) {
                    notification.show(qsTr("Please wait until current task is complete."));
                    return false;
                }

                // Entry not cached and offline mode enabled
                if (settings.offlineMode && !model.cached) {
                    notification.show(qsTr("Offline version not available."));
                    return false;
                }

                // Switch to Offline mode if no network
                if (!settings.offlineMode && !dm.online) {
                    if (model.cached) {
                        // Entry cached
                        notification.show(qsTr("Network connection is unavailable.\nSwitching to Offline mode."));
                        settings.offlineMode = true;
                    } else {
                        // Entry not cached
                        notification.show(qsTr("Network connection is unavailable."));
                        return false;
                    }
                }

                return true;
            }

            function openEntryInViewer() {

                // (!dm.online && settings.offlineMode) -> WORKAROUND for https://github.com/mkiol/kaktus/issues/14
                if (!dm.online && settings.offlineMode) {
                    openInExaternalBrowser(model.index, model.link, model.uid);
                    return;
                }

                pageStack.push(Qt.resolvedUrl("WebPreviewPage.qml"),
                               {"entryId": model.uid,
                                   "onlineUrl": delegate.onlineurl,
                                   "offlineUrl": delegate.offlineurl,
                                   "title": model.title,
                                   "stared": model.readlater==1,
                                   "index": model.index,
                                   "feedindex": root.index,
                                   "read" : model.read==1,
                                   "cached" : model.cached
                               });
            }

            function showEntryFeedContent() {
                pageStack.push(Qt.resolvedUrl("FeedContentPage.qml"),
                               {"entryId": model.uid,
                                   "content":model.contentraw,
                                   "onlineUrl": delegate.onlineurl,
                                   "offlineUrl": delegate.offlineurl,
                                   "title": model.title,
                                   "stared": model.readlater==1,
                                   "index": model.index,
                                   "feedindex": root.index,
                                   "read" : model.read==1,
                                   "cached" : model.cached
                               });
            }

            function openEntry() {

                if (settings.clickBehavior === 2) {
                    showEntryFeedContent();
                    return;
                }

                if (!check()) {
                    return;
                }

                if (settings.clickBehavior === 1) {
                    openInExaternalBrowser(model.index, model.link, model.uid);
                    return;
                }

                openEntryInViewer();
            }

            Component.onCompleted: {
                //Dynamic creation of new items if last item is compleated
                //console.log("index:",index,"count:",entryModel.count());
                if (index==entryModel.count()-2) {
                    //console.log("index==entryModel.count()-2");
                    entryModel.createItems(index+2,settings.offsetLimit);
                }
            }

            onClicked: {
                //console.log("id",model.uid, "date", model.date);
                //console.log("content",model.content);
                //console.log("contentall",model.contentall);
                if (timer.running) {
                    // Double click
                    timer.stop();
                    doubleEntryClicked();
                } else {
                    timer.start();
                }
            }

            onDoubleEntryClicked: {
                if (model.read === 0) {
                    entryModel.setData(model.index, "read", 1, "");
                    //read = 1;
                } else {
                    entryModel.setData(model.index, "read", 0, "");
                    //read = 0;
                }
            }

            onSingleEntryClicked: {
                // Landscape mode
                if (root.landscapeMode) {
                    delegate.expanded = true;
                    return;
                }

                // Portrait mode
                openEntry();
            }

            Timer {
                id: timer
                interval: 400
                onTriggered: {
                    // Single click
                    /*console.log("date: "+model.date);
                    console.log("read: "+model.read);
                    console.log("readlater: "+model.readlater);
                    console.log("image: "+model.image);
                    console.log("feedIcon: "+feedIcon+" model.feedIcon: "+model.feedIcon);
                    console.log("showMarkedAsRead: "+showMarkedAsRead);*/
                    singleEntryClicked();
                }
            }

            onExpandedChanged: {
                if (expanded) {
                    // Collapsing all other items on expand
                    for (var i = 0; i < listView.contentItem.children.length; i++) {
                        var curItem = listView.contentItem.children[i];
                        if (curItem !== delegate) {
                            if (curItem.objectName==="EntryDelegate") {
                                if (curItem.expanded)
                                    curItem.expanded = false;
                            }
                        }
                    }

                    root.expandedDelegate = delegate;
                    root.expandedUid = delegate.uid;
                    root.expandedIndex = delegate.index;
                } else {
                    if (delegate === root.expandedDelegate) {
                        root.expandedDelegate = null;
                        root.expandedUid = "";
                        root.expandedIndex = 0;
                    }
                }
            }

            onMarkedAsRead: {
                entryModel.setData(model.index, "read", 1, "");
            }

            onMarkedAsUnread: {
                entryModel.setData(model.index, "read", 0, "");
            }

            onMarkedReadlater: {
                entryModel.setData(index, "readlater", 1, "");
            }

            onUnmarkedReadlater: {
                entryModel.setData(index, "readlater", 0, "");
            }

            onMarkedLike: {
                entryModel.setData(model.index, "liked", true, "");
            }

            onUnmarkedLike: {
                entryModel.setData(model.index, "liked", false, "");
            }

            onMarkedBroadcast: {
                pageStack.push(Qt.resolvedUrl("ShareDialog.qml"),{"index": model.index,});
                //entryModel.setData(model.index, "broadcast", true, "");
            }

            onUnmarkedBroadcast: {
                entryModel.setData(model.index, "broadcast", false, "");
            }

            onMarkedAboveAsRead: {
                entryModel.setAboveAsRead(model.index);
            }

            onShowFeedContent: {
                showEntryFeedContent();
            }

            onOpenInBrowser: {
                if (!check()) {
                    return;
                }

                openInExaternalBrowser(model.index, model.link, model.uid);
            }

            onOpenInViewer: {
                if (!check()) {
                    return;
                }

                openEntryInViewer();
            }
        }

        ViewPlaceholder {
            id: placeholder
            enabled: listView.count == 0
            text: fetcher.busy ? qsTr("Wait until Sync finish.") :
                      settings.viewMode==4 ? app.isNetvibes || app.isFeedly ? qsTr("No saved items") : qsTr("No starred items")  :
                      settings.viewMode==6 ? qsTr("No liked items") : settings.showOnlyUnread ? qsTr("No unread items") : qsTr("No items")
        }

        /*Component.onCompleted: {
            if (listView.count == 0 && settings.viewMode>2)
                bar.open();
        }*/

        VerticalScrollDecorator {
            flickable: listView
        }
    }

    EntryPageContent {
        id: contentPanel
        property bool expanded: false

        visible: root.landscapeMode && active
        anchors.right: root.right; anchors.top: root.top
        width: expanded ? root.width : app.landscapeContentPanelWidth
        clip: true
        height: app.flickHeight
        //openable: root.expandedUid != "" && !dm.busy && !fetcher.busy && !dm.removerBusy && !app.isTablet
        openable: false
        textFormat: app.isTablet ? Text.StyledText : Text.PlainText

        onClicked: {
            /*if (isTablet) {
                var delegate = root.expandedDelegate ? root.expandedDelegate : root.expandedUid !="" ? getDelegateByUid(root.expandedUid) : undefined;
                if (delegate)
                    delegate.openEntry();
            } else {
                expanded = !expanded;
            }*/

            var delegate = root.expandedDelegate ? root.expandedDelegate : root.expandedUid !="" ? getDelegateByUid(root.expandedUid) : undefined;
            if (delegate)
                delegate.openEntry();
        }

        onOpenClicked: {
            var delegate = root.expandedDelegate ? root.expandedDelegate : root.expandedUid !="" ? getDelegateByUid(root.expandedUid) : undefined;
            if (delegate)
                delegate.openEntry();
        }

        busy: (width != root.width) && (width != app.landscapeContentPanelWidth)

        //Behavior on width { NumberAnimation { duration: 200;easing.type: Easing.OutQuad } }
    }

    HintLabel {
        anchors.bottom: parent.bottom
        backgroundColor: Theme.highlightDimmerColor
        Behavior on opacity { FadeAnimation { duration: 400 } }
        opacity: settings.getHint1Done() ? 0.0 : 1.0
        //opacity: 1.0
        visible: opacity != 0

        text: qsTr("One-tap to open article, double-tap to mark as read")

        MouseArea {
            anchors.fill: parent
            onPressed: {
                settings.setHint1Done(true);
                parent.opacity = 0.0;
            }
        }
    }
}
