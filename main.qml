import QtQuick 2.13
import QtQuick.Window 2.13

Window {
    id: main
    width: 1920
    height: 1080
    visible: true
    title: qsTr("Tube Scanning Application")
    readonly property string label_waiting_id: "Waiting on ID Scan"
    readonly property string label_waiting_rackid: "Waiting on Rack ID Scan"
    readonly property string label_waiting_tube: "Waiting on Tube Scan"
    readonly property string label_rack_id: "Rack ID: "
    readonly property string label_tube_count: "Test Tube Count: "
    readonly property int max_tube_count: 48
    property var barcode_data: []
    property var barcode_users: []
    property var barcode_tubes: []
    property variant current_scan_json: {"well": "", "sid": "", "ttuid": "", "datetime" : ""}
    property string rack_id: ""
    property string well_row: "A"
    property variant well_col: 1
    property int tube_count: 0
    property string backup_filename: "rack_data_"
    property string last_color: ""
    property string file_name: ""
    property string file_directory: ""
    property variant calibrant_locations: ["A1","E1", "I1"]
    property variant is_calibrant_locked: true
    property variant recent_undo: false
    property variant minutes_seconds_map: ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X"]

    function reset_data(){
        date_time_label.text = ""
        rack_id_lbl.text = ""
        current_scan_json.well = ""
        current_scan_json.sid = ""
        current_scan_json.ttuid = ""
        well_col = 1
        well_row = "A"
        rack_id = ""
        tube_count = 0
        barcode_data = []
        barcode_users = []
        barcode_tubes = []
        backup_filename = "rack_data_"
        if(last_color !== ""){
            status_text.color = last_color
            last_color = ""
        }
        var file_obj = get_file_name()
        file_name = file_obj.filename
        file_directory = file_obj.directory

        status_text.text = label_waiting_rackid
        well_model.clear()
    }

    function get_file_name(){
        var current_datetime = new Date();
        var current_folder_format = (current_datetime.getMonth()+1)  + "_" + current_datetime.getDate() + "_" + current_datetime.getFullYear()
        var current_date_format = (current_datetime.getMonth()+1)  + "_" + current_datetime.getDate() + "_" + current_datetime.getFullYear() + "_" +
                current_datetime.getHours() + "_" + current_datetime.getMinutes() + "_" + current_datetime.getSeconds()
        var current_directory = "backup/" + current_folder_format + "/"
        return  { "filename": current_directory + backup_filename + current_date_format + ".json", "directory" : current_directory }
    }

    function populate_date_field(){
        var current_datetime = new Date();
        var hours = current_datetime.getHours()
        var ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        var current_date_format = ("0" + (current_datetime.getMonth()+1)).slice(-2)  + "/" + ("0" + current_datetime.getDate()).slice(-2) + "/" + current_datetime.getFullYear() + " " +
                ("0" + hours).slice(-2) + ":" + ("0" + current_datetime.getMinutes()).slice(-2) + " " + ampm.toUpperCase()
        date_time_label.text = current_date_format
    }

    function get_datetime_formatted(){
        var current_datetime = new Date();
        var hours = current_datetime.getHours()
        var ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        var current_date_format = ("0" + (current_datetime.getMonth()+1)).slice(-2)  + "/" + ("0" + current_datetime.getDate()).slice(-2) + "/" + current_datetime.getFullYear() + " " +
                ("0" + hours).slice(-2) + ":" + ("0" + current_datetime.getMinutes()).slice(-2) + " " + ampm.toUpperCase()
        return current_date_format
    }

    function get_time_base60(){
        var current_datetime = new Date();
        var hours = minutes_seconds_map[current_datetime.getHours()]
        var mins = minutes_seconds_map[current_datetime.getMinutes()]
        var seconds = minutes_seconds_map[current_datetime.getSeconds()]
        return hours+mins+seconds
    }

    function get_date(){
        var current_datetime = new Date();
        var date = ("0" + (current_datetime.getMonth()+1)).slice(-2)  + "/" + ("0" + current_datetime.getDate()).slice(-2) + "/" + current_datetime.getFullYear();
        return date;
    }

    Component.onCompleted: {
        reset_data()
        scan_input.forceActiveFocus()
        status_text.text = label_waiting_rackid
    }

    TextInput {
        id: scan_input
        focus: true
        x: 1254
        y: -38
        width: 354
        height: 56
        visible: true
        text: qsTr("")
        font.pixelSize: 60
        selectionColor: "#5e68f6"
        Keys.onReturnPressed: {
            if(barcode_data.length < max_tube_count && !modal_background.visible){
                print("tubes less than max count!")
                if(calibrant_locations.includes(barcode_data.length)){
                    print("found calibrant")
                    //Current position is calibrant, move until not
                    while(calibrant_locations.includes(barcode_data.length)){
                        current_scan_json.well = well_row + well_col
                        current_scan_json.sid = "C"
                        current_scan_json.ttuid = "C"
                        current_scan_json.datetime = get_datetime_formatted()
                        well_model.append(current_scan_json)
                        barcode_data.push(JSON.stringify(current_scan_json))
                        barcode_users.push('{"sid": "'+current_scan_json.sid+'", "well": "'+current_scan_json.well +'", "t": "'+get_time_base60() + '" }')
                        barcode_tubes.push('{"ttuid": "'+current_scan_json.ttuid+'", "well": "'+current_scan_json.well+'" }')
                        var data_tubes = '{"rackid": "' + rack_id + '","' +'"date":'+  +'",data": [' + barcode_tubes + ']}'
                        var data_sid = '{"rackid": "' + rack_id + '", "data": [' + barcode_users + ']}'                        //Advnace well position
                        if(well_col % 4 === 0){
                            well_row = String.fromCharCode(well_row.charCodeAt() + 1);
                            well_col = 1
                        }else{
                            print("col advnace")
                            well_col++
                        }
                        current_scan_json.well = ""
                        current_scan_json.sid = ""
                        current_scan_json.ttuid = ""
                        current_scan_json.datetime = ""
                    }
                }
                if(status_text.text === label_waiting_rackid){
                    //Rack ID
                    print("setting rack id")
                    populate_date_field()
                    rack_id = scan_input.text
                    rack_id_lbl.text = label_rack_id + rack_id
                    status_text.text = label_waiting_id
                    scan_input.text = ""
                    status_text.forceLayout()
                }else if(status_text.text === label_waiting_id){
                    recent_undo = false
                    undo_scan_rect.color = "#034fc9"
                    //Ensure that Undo has not set this property
                    //if(current_scan_json.well === ""){
                    current_scan_json.well = well_row + well_col
                    //}
                    current_scan_json.sid = scan_input.text
                    scan_input.text = ""
                    status_text.text = label_waiting_tube
                }else if(status_text.text === label_waiting_tube){
                    current_scan_json.ttuid = scan_input.text
                    current_scan_json.datetime = get_datetime_formatted()
                    scan_input.text = ""
                    status_text.text = label_waiting_id
                    if(well_col % 4 === 0){
                        well_row = String.fromCharCode(well_row.charCodeAt() + 1);
                        well_col = 1
                    }else{
                        well_col++
                    }
                    tube_count++
                    test_tube_count_lbl.text = label_tube_count + tube_count

                    well_model.append(current_scan_json)
                    barcode_data.push(JSON.stringify(current_scan_json))
                    barcode_users.push('{"sid": "'+current_scan_json.sid+'", "well": "'+current_scan_json.well +'", "t": "'+get_time_base60() + '" }')
                    barcode_tubes.push('{"ttuid": "'+current_scan_json.ttuid+'", "well": "'+current_scan_json.well+'" }')
                    sid_confirmation_label.text = current_scan_json.sid
                    ttuid_confirmation_label.text = current_scan_json.ttuid
                    current_scan_json.well = ""
                    current_scan_json.sid = ""
                    current_scan_json.ttuid = ""
                    current_scan_json.datetime = ""
                    var data = '{"rackid": "' + rack_id + '", "data": [' + barcode_data + ']}'

                    var data_tubes = '{"rackid": "' + rack_id + '",' + '"date":"'+ get_date() +'","data": [' + barcode_tubes + ']}'
                    var data_sid = '{"rackid": "' + rack_id + '", "data": [' + barcode_users + ']}'
                    barcode_utils.generate_barcode(data_sid, data_tubes, barcode_data, file_directory, file_name)
                    barcode_users_img.reloadImage()
                    barcode_tubes_img.reloadImage()

                    if(calibrant_locations.includes(barcode_data.length)){
                        print("found calibrant")
                        //Current position is calibrant, move until not
                        while(calibrant_locations.includes(barcode_data.length)){
                            current_scan_json.well = well_row + well_col
                            current_scan_json.sid = "C"
                            current_scan_json.ttuid = "C"
                            current_scan_json.datetime = get_datetime_formatted()
                            well_model.append(current_scan_json)
                            barcode_data.push(JSON.stringify(current_scan_json))
                            barcode_users.push('{"sid": "'+current_scan_json.sid+'", "well": "'+current_scan_json.well +'", "t": "'+get_time_base60() + '" }')
                            barcode_tubes.push('{"ttuid": "'+current_scan_json.ttuid+'", "well": "'+current_scan_json.well+'" }')
                            var data_tubes = '{"rackid": "' + rack_id + '","' +'"date":'+ get_date() +'",data": [' + barcode_tubes + ']}'
                            //Advnace well position
                            if(well_col % 4 === 0){
                                well_row = String.fromCharCode(well_row.charCodeAt() + 1);
                                well_col = 1
                            }else{
                                well_col++
                            }
                        }
                        data_tubes = '{"rackid": "' + rack_id + '","' +'"date":'+ get_date() +'",data": [' + barcode_tubes + ']}'
                        data_sid = '{"rackid": "' + rack_id + '", "data": [' + barcode_users + ']}'
                        barcode_utils.generate_barcode(data_sid, data_tubes, barcode_data, file_directory, file_name)

                    }
                    if(barcode_data.length >= max_tube_count){
                        status_text.text = "Rack Full!"
                        last_color = status_text.color
                        status_text.color = "#bf0000"
                    }

                    confirm_scan_modal.visible = true
                    modal_background.visible = true


                }

            }else{
                //status_text.text = "Rack Full!"
                //last_color = status_text.color
                //status_text.color = "#bf0000"
            }

            print("enter pressed")
            //barcode_utils.generate_barcode(text)
            //barcode_users_img.reloadImage()
        }
    }

    Image {
        id: background_img
        anchors.fill: parent
        source: "Images/blueBack.jpg"
        fillMode: Image.Stretch


        Rectangle {
            id: title_background
            x: 8
            y: 2
            width: 1912
            height: 68
            color: "#8ba9e6"
            radius: 15
            border.color: "#020202"
        }
        Text {
            id: title_text
            objectName: "title_text"
            x: 0
            y: 0
            width: 1920
            height: 64
            color: "#ffffff"
            text: qsTr("SpectraPass Accessioning")
            font.pixelSize: 55
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            font.family: "Times New Roman"
            minimumPointSize: 28
            minimumPixelSize: 58
        }
    }


    Rectangle {
        id: print_data
        objectName:  "printData"
        focus: true
        x: 86
        y: 88
        width: 1772
        height: 942
        radius: 20
        border.color: "#1a4bf2"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#a1c4fd"
            }

            GradientStop {
                position: 1
                color: "#c2e9fb"
            }
        }



        Rectangle {
            id: print_area
            x: 469
            y: 49
            width: 816
            height: 885
            color: "#ffffff"
            border.width: 0

            Image {
                id: barcode_tubes_img
                x: 457
                y: 554
                width: 329
                height: 329
                source: "current_tubes_barcode.png"
                cache: false
                fillMode: Image.PreserveAspectFit
                function reloadImage() {
                    let oldSource = source
                    source = ""
                    source = oldSource
                }
            }

            Image {
                id: barcode_users_img
                cache: false
                x: 31
                y: 553
                width: 329
                height: 329
                source: "current_users_barcode.png"
                fillMode: Image.PreserveAspectFit
                function reloadImage() {
                    let oldSource = source
                    source = ""
                    source = oldSource
                }
            }

            GridView {
                id: rack_grid
                objectName: "rack_grid"
                x: 12
                y: 87
                width: 793
                height: 404
                flickableDirection: Flickable.VerticalFlick
                snapMode: GridView.NoSnap
                keyNavigationWraps: false
                cacheBuffer: 320
                cellWidth: 198
                cellHeight: 35

                delegate: Item {

                    Rectangle {
                        width: 198
                        height: 35
                        MouseArea {
                            anchors.fill:  parent
                            onClicked: {
                                print("location")
                            }
                        }
                        Column {
                            Text {
                                x: 0
                                text: well
                                font.bold: true
                                color: "darkblue"
                                anchors.horizontalCenter:  parent.horizontalCenter
                                horizontalAlignment:  Text.AlignLeft
                                width: 30
                                font.pixelSize: 14

                            }
                        }

                        Column {
                            x: 30
                            height: 35
                            width: 190
                            spacing: 1

                            Text {
                                x: 5
                                text: "ID: " + sid
                                font.bold: true
                                anchors.left: parent.left
                                font.pixelSize: 12
                                color: "#856800"
                            }

                            Text {
                                x: 5
                                text: "TTUID: " +  ttuid
                                font.bold: true
                                anchors.left: parent.left
                                font.pixelSize: 12
                                color: "#4D4732"
                            }

                        }
                    }
                }
                model: ListModel {
                    id: well_model
                    ListElement {
                        well: "asdfasdf"
                        sid: "grey"
                        ttuid: ""
                    }
                    ListElement {
                        well: "asdfasdf"
                        sid: "grey"
                        ttuid: ""
                    }
                    ListElement {
                        well: "asdfasdf"
                        sid: "grey"
                        ttuid: ""
                    }
                    ListElement {
                        well: "asdfasdf"
                        sid: "grey"
                        ttuid: ""
                    }
                }


                Component.onCompleted: {
                    well_model.clear()
                    print("appending")
                    /*populate_date_field()
                    var barcode_data = ""
                    var well_row = 'A'
                    var well_col = 1
                    var spectra_id = Math.random().toString(36).substr(2,13).toUpperCase()
                    for(var i = 1; i <= max_tube_count; i++){
                        print("appending")
                        if(barcode_data.length === 1){
                            barcode_data = barcode_data + "/"
                        }

                        var position = well_row + well_col
                        if(i % 3 == 0){
                            spectra_id = Math.random().toString(36).substr(2,13).toUpperCase()
                        }
                        var tube_id = Math.random().toString(36).substr(2,13).toUpperCase()
                        barcode_data = barcode_data + "" + spectra_id + "+" + tube_id  +"/"
                        current_scan_json.well = position
                        current_scan_json.ttuid = tube_id
                        current_scan_json.sid = spectra_id
                        well_model.append(current_scan_json)
                        if(well_col % 4 === 0){
                            well_row = String.fromCharCode(well_row.charCodeAt() + 1);
                            well_col = 1
                        }else{
                            well_col++
                        }
                    }
                    barcode_data = barcode_data + ""
                    barcode_utils.generate_barcode(barcode_data)
                    barcode_users_img.reloadImage()
                    well_model.sync()
                    forceLayout()*/
                }

            }

            Text {
                id: user_barcode_lbl
                x: 31
                y: 528
                width: 329
                height: 23
                text: qsTr("SID Barcode")
                font.pixelSize: 19
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: user_barcode_lbl1
                x: 457
                y: 531
                width: 329
                height: 23
                text: qsTr("TTUID Barcode")
                font.pixelSize: 19
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: rack_id_lbl
                x: 8
                y: 5
                width: 290
                height: 22
                color: "#000000"
                text: qsTr("Rack ID:  ABCDEFGHIJKL")
                font.pixelSize: 16
                style: Text.Raised
                font.styleName: "Bold"
                font.weight: Font.Bold
                styleColor: "#0712a7"
                font.family: "Verdana"
                font.bold: true
            }

            Text {
                id: test_tube_count_lbl
                x: 335
                y: 5
                width: 201
                height: 22
                color: "#000000"
                text: qsTr("Test Tube Count:")
                font.pixelSize: 16
                style: Text.Raised
                styleColor: "#000000"
                font.bold: true
                font.styleName: "Bold"
                font.weight: Font.Bold
                font.family: "Verdana"
            }

            Image {
                id: image
                x: 614
                y: 2
                width: 201
                height: 28
                source: "Images/spectrapass_logo.png"
                mirror: false
                sourceSize.height: 54
                smooth: true
                autoTransform: false
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: date_time_label
                x: 637
                y: 30
                width: 155
                height: 15
                text: qsTr("")
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                font.styleName: "Bold"
            }

            Text {
                id: text10
                x: 324
                y: 48
                width: 313
                height: 41
                text: qsTr("Print: ______________________")
                font.pixelSize: 26
            }

            Text {
                id: text9
                x: 8
                y: 47
                width: 309
                height: 41
                text: qsTr("Sign: ______________________")
                font.pixelSize: 26
            }




        }



        Rectangle {
            id: printManifest
            x: 35
            y: 580
            width: 396
            height: 79
            radius: 14
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    print("clicked print")

                    print_area.grabToImage(function(result) {
                        result.saveToFile("something.png");
                    }, Qt.size( 5060, 5634));

                    barcode_utils.handle_print()

                }
            }

            Text {
                id: text4
                x: 0
                y: 8
                width: 396
                height: 63
                color: "#ffffff"
                text: qsTr("Print Manifest")
                font.pixelSize: 53
                horizontalAlignment: Text.AlignHCenter
                style: Text.Raised
                styleColor: "#000000"
                font.bold: true
                font.styleName: "Bold"
                font.weight: Font.Bold
                font.family: "Times New Roman"
            }
        }

        Rectangle {
            id: print_both_rect
            x: 35
            y: 755
            width: 396
            height: 79
            visible: false
            radius: 9
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            Text {
                id: text5
                x: 8
                y: 8
                width: 396
                height: 63
                color: "#ffffff"
                text: qsTr("Print")
                font.pixelSize: 53
                horizontalAlignment: Text.AlignHCenter
                style: Text.Raised
                styleColor: "#000000"
                font.styleName: "Bold"
                font.bold: true
                font.weight: Font.Bold
                font.family: "Times New Roman"
            }
        }

        Rectangle {
            id: print_qr_code_rect
            x: 41
            y: 670
            width: 396
            height: 79
            visible: false
            radius: 9
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            Text {
                id: text6
                x: 0
                y: 8
                width: 396
                height: 63
                color: "#ffffff"
                text: qsTr("Print QRCode")
                font.pixelSize: 53
                horizontalAlignment: Text.AlignHCenter
                style: Text.Raised
                styleColor: "#000000"
                font.styleName: "Bold"
                font.bold: true
                font.weight: Font.Bold
                font.family: "Times New Roman"
            }
        }

        Rectangle {
            id: undo_scan_rect
            x: 41
            y: 366
            width: 396
            height: 79
            visible: false
            color: "#00380c"
            radius: 9
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(!recent_undo){
                        if(status_text.text === label_rack_id && tube_count == 0){
                            //Nothing ot undo
                        }else if(status_text.text === label_waiting_id || status_text.text === "Rack Full!"){
                            //Undo previous scan
                            var removed_item
                            var json_data

                            do{
                                //keep popping until we popped a real data point.
                                removed_item = barcode_data.pop()
                                barcode_users.pop()
                                barcode_tubes.pop()
                                print("popped: " + removed_item )
                                if(removed_item !== undefined){
                                    json_data = JSON.parse(removed_item)
                                }
                                well_model.remove(well_model.count - 1)
                            }while(removed_item !== undefined && json_data.sid === "C")

                            tube_count--
                            if(removed_item !== undefined){
                                well_row = json_data.well[0]
                                well_col = json_data.well[1]
                            }else{
                                well_row = "A"
                                well_col = 1
                            }
                            current_scan_json.well = ""
                            current_scan_json.sid = ""
                            current_scan_json.ttuid = ""
                            current_scan_json.datetime = ""
                            recent_undo = true
                            undo_scan_rect.color = "#222222"
                            undo_scan_rect.update()
                            status_text.text = label_waiting_id

                        }else if(status_text.text === label_waiting_tube){
                            //Reset Current Scan
                            well_row = current_scan_json.well[0]
                            well_col = current_scan_json.well[1]
                            current_scan_json.well = ""
                            current_scan_json.sid = ""
                            current_scan_json.ttuid = ""
                            current_scan_json.datetime = ""
                            recent_undo = true

                            status_text.text = label_waiting_id
                            undo_scan_rect.color = "#222222"
                            undo_scan_rect.update()

                        }
                    }
                }
            }

            Text {
                id: text7
                x: 0
                y: 8
                width: 396
                height: 63
                color: "#ffffff"
                text: qsTr("Undo Last Scan")
                font.pixelSize: 53
                horizontalAlignment: Text.AlignHCenter
                style: Text.Raised
                styleColor: "#000000"
                font.styleName: "Bold"
                font.bold: true
                font.weight: Font.Bold
                font.family: "Times New Roman"
            }
        }

        Rectangle {
            id: new_rack_rect
            x: 35
            y: 186
            width: 396
            height: 79
            radius: 9

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    print("new rack creation")
                    confirm_new_rack_modal.visible = true
                    modal_background.visible = true
                }
            }

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            Text {
                id: text8
                x: 0
                y: 8
                width: 396
                height: 63
                color: "#ffffff"
                text: qsTr("New Rack")
                font.pixelSize: 53
                horizontalAlignment: Text.AlignHCenter
                style: Text.Raised
                styleColor: "#000000"
                font.bold: true
                font.styleName: "Bold"
                font.weight: Font.Bold
                font.family: "Times New Roman"
            }
        }

        Text {
            id: status_text
            x: 469
            y: 1
            width: 816
            height: 69
            color: "#005e15"
            text: qsTr("Waiting on ID Scan")
            font.pixelSize: 43
            horizontalAlignment: Text.AlignHCenter
            minimumPixelSize: 14
            font.weight: Font.Bold
            styleColor: "#351ad8"
            font.styleName: "Bold"
            font.family: "Courier"
            style: Text.Raised
            font.bold: true
        }

        GridView {
            id: gridView
            x: 1402
            y: 68
            width: 330
            height: 860
            interactive: false
            boundsBehavior: Flickable.OvershootBounds
            flickableDirection: Flickable.VerticalFlick
            model: ListModel {
                id: calibration_model
                ListElement {
                    index: 0
                    well: "A1"
                    isCalibrant: false
                    color_code: "grey"
                }

                ListElement {
                    index: 1
                    well: "A2"
                    isCalibrant: false
                    color_code: "grey"
                }

                ListElement {
                    index: 2
                    well: "A3"
                    isCalibrant: false
                    color_code: "grey"
                }

                ListElement {
                    index: 3
                    well: "A4"
                    isCalibrant: false
                    color_code: "grey"
                }
            }
            cellHeight: 70
            delegate: Item {
                x: 5
                height: 50
                Column {
                    spacing: 5
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 40
                        color: color_code
                        anchors.horizontalCenter: parent.horizontalCenter
                        MouseArea {
                            anchors.fill:  parent
                            onClicked: {
                                if(!is_calibrant_locked){
                                    print("calibrant: " +  index)
                                    print(calibrant_locations)
                                    if(!calibrant_locations.includes(index)){
                                        calibrant_locations.push(index)
                                        calibration_model.setProperty(index,"color_code","#ff0000")
                                        calibration_model.setProperty(index,"isCalibrant",true)
                                    }else{
                                        calibration_model.setProperty(index,"color_code","#222222")
                                        calibration_model.setProperty(index,"isCalibrant",false)
                                        var el_index = calibrant_locations.indexOf(index)
                                        calibrant_locations.splice(el_index, 1)
                                    }
                                    print(calibrant_locations)
                                }
                            }
                        }
                    }



                    Text {
                        x: 5
                        z: 1
                        text: well
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.bold: true
                    }


                }
                Rectangle {
                    x: 45
                    y: 45

                    width: 20
                    height: 20
                    radius: 40
                    z: 0
                    //anchors.horizontalCenter: parent.horizontalCenter
                    visible: false//well === "B2" ? true : false
                }
            }
            cellWidth: 70

            Component.onCompleted: {
                calibration_model.clear()
                var well_row = 'A'
                var well_col = 1
                var index_array = []
                for(var i = 1; i <= max_tube_count; i++){
                    var position = well_row + well_col
                    var color = "#222222"
                    var isCalibrant = false
                    if(calibrant_locations.includes(position)){
                        index_array.push(i-1)
                        color = "#ff0000"
                        isCalibrant = true
                    }

                    calibration_model.append({"index": i-1,"well": position, "isCalibrant":isCalibrant, "color_code": color})
                    if(well_col % 4 === 0){
                        well_row = String.fromCharCode(well_row.charCodeAt() + 1);
                        well_col = 1
                    }else{
                        well_col++
                    }
                }
                print(index_array)
                calibrant_locations = []
                calibrant_locations = index_array
                print(calibrant_locations)

            }
        }

        Rectangle {
            id: unlock_button
            x: 1392
            y: 10
            width: 268
            height: 52
            radius: 9

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    is_calibrant_locked = !is_calibrant_locked
                    if(is_calibrant_locked){
                        unlock_button_text.text = "Unlock"
                    }else{
                        unlock_button_text.text = "Lock"
                    }
                }
            }

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            Text {
                id: unlock_button_text
                x: 8
                y: 0
                width: 252
                height: 51
                color: "#ffffff"
                text: qsTr("Unlock")
                font.pixelSize: 30
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                textFormat: Text.PlainText
                font.weight: Font.Bold
                styleColor: "#011ca1"
                font.styleName: "Bold"
                font.bold: true
                font.family: "Times New Roman"
                style: Text.Raised
            }
        }



    }


    Image {
        id: modal_background
        opacity: 0.6
        visible: false
        anchors.fill: parent
        source: "Images/BlueBackground.jpg"
        fillMode: Image.Stretch
    }




    Rectangle {
        id: confirm_scan_modal
        x: 506
        y: 290
        width: 909
        height: 500
        visible: false
        color: "#ffffff"
        radius: 15
        border.color: "#bec5e3"
        border.width: 13
        z: 0

        Text {
            id: text1
            x: 50
            y: 26
            width: 810
            height: 84
            text: qsTr("Confirm scan data below is accurate before next scan:")
            font.pixelSize: 36
            wrapMode: Text.Wrap
            font.weight: Font.Bold
            font.family: "Courier"
        }

        Text {
            id: text2
            x: 50
            y: 172
            width: 390
            height: 36
            text: qsTr("User's ID:")
            font.pixelSize: 30
            horizontalAlignment: Text.AlignRight
            font.family: "Verdana"
            font.weight: Font.ExtraBold
        }

        Text {
            id: text3
            x: 50
            y: 241
            width: 390
            height: 36
            text: qsTr("Test Tube ID:")
            font.pixelSize: 30
            horizontalAlignment: Text.AlignRight
            font.family: "Verdana"
            font.weight: Font.ExtraBold
        }

        Text {
            id: sid_confirmation_label
            x: 446
            y: 172
            width: 390
            height: 36
            text: qsTr("")
            font.pixelSize: 30
            font.family: "Verdana"
            font.weight: Font.ExtraBold
        }

        Text {
            id: ttuid_confirmation_label
            x: 446
            y: 241
            width: 390
            height: 36
            text: qsTr("")
            font.pixelSize: 30
            font.family: "Verdana"
            font.weight: Font.ExtraBold
        }

        Rectangle {
            id: confirm_modal_button
            x: 70
            y: 362
            width: 351
            height: 68
            radius: 9

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    confirm_scan_modal.visible = false
                    modal_background.visible = false
                    scan_input.text = ""
                }
            }

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            Text {
                id: confirm_scan2
                x: 4
                y: 2
                width: 347
                height: 68
                color: "#ffffff"
                text: qsTr("Confirm")
                font.pixelSize: 47
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                style: Text.Raised
                styleColor: "#011ca1"
                font.family: "Times New Roman"
                textFormat: Text.PlainText
                minimumPixelSize: 23
                font.weight: Font.Bold
                font.styleName: "Bold"
                font.bold: true
            }
        }

        Rectangle {
            id: undo_modal_button
            x: 466
            y: 362
            width: 351
            height: 68
            radius: 9

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(!recent_undo){
                        if(status_text.text === label_rack_id && tube_count == 0){
                            //Nothing ot undo
                        }else if(status_text.text === label_waiting_id || status_text.text === "Rack Full!"){
                            //Undo previous scan
                            var removed_item
                            var json_data

                            do{
                                //keep popping until we popped a real data point.
                                removed_item = barcode_data.pop()
                                barcode_users.pop()
                                barcode_tubes.pop()
                                print("popped: " + removed_item )
                                if(removed_item !== undefined){
                                    json_data = JSON.parse(removed_item)
                                }
                                well_model.remove(well_model.count - 1)
                            }while(removed_item !== undefined && json_data.sid === "C")

                            tube_count--
                            if(removed_item !== undefined){
                                well_row = json_data.well[0]
                                well_col = json_data.well[1]
                            }else{
                                well_row = "A"
                                well_col = 1
                            }
                            current_scan_json.well = ""
                            current_scan_json.sid = ""
                            current_scan_json.ttuid = ""
                            current_scan_json.datetime = ""
                            recent_undo = true
                            undo_scan_rect.color = "#222222"
                            undo_scan_rect.update()
                            status_text.text = label_waiting_id

                        }else if(status_text.text === label_waiting_tube){
                            //Reset Current Scan
                            well_row = current_scan_json.well[0]
                            well_col = current_scan_json.well[1]
                            current_scan_json.well = ""
                            current_scan_json.sid = ""
                            current_scan_json.ttuid = ""
                            current_scan_json.datetime = ""
                            recent_undo = true

                            status_text.text = label_waiting_id
                            undo_scan_rect.color = "#222222"
                            undo_scan_rect.update()

                        }
                        confirm_scan_modal.visible = false
                        modal_background.visible = false
                        scan_input.text = ""
                    }
                }
            }

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            Text {
                id: confirm_scan3
                x: 4
                y: 2
                width: 347
                height: 68
                color: "#ffffff"
                text: qsTr("Undo Scan")
                font.pixelSize: 47
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                style: Text.Raised
                styleColor: "#011ca1"
                font.family: "Times New Roman"
                textFormat: Text.PlainText
                minimumPixelSize: 23
                font.bold: true
                font.styleName: "Bold"
                font.weight: Font.Bold
            }
        }



    }

    Rectangle {
        id: confirm_new_rack_modal
        x: 506
        y: 442
        width: 909
        height: 197
        visible: false
        color: "#ffffff"
        radius: 15
        border.color: "#bec5e3"
        border.width: 13
        z: 0
        Text {
            id: text11
            x: 18
            y: 12
            width: 878
            height: 84
            text: qsTr("Start New Rack?")
            font.pixelSize: 36
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.weight: Font.Bold
            font.family: "Courier"
        }

        Rectangle {
            id: yes_new_rack_button
            x: 18
            y: 102
            width: 351
            height: 68
            visible: true
            radius: 9
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            Text {
                id: confirm_scan4
                x: 4
                y: 2
                width: 347
                height: 68
                color: "#ffffff"
                text: qsTr("Yes")
                font.pixelSize: 47
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.weight: Font.Bold
                font.styleName: "Bold"
                minimumPixelSize: 23
                styleColor: "#011ca1"
                textFormat: Text.PlainText
                style: Text.Raised
                font.family: "Times New Roman"
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    reset_data()
                    modal_background.visible = false
                    confirm_new_rack_modal.visible = false
                }
            }

        }

        Rectangle {
            id: no_new_rack_button
            x: 545
            y: 102
            width: 351
            height: 68
            radius: 9
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#034fc9"
                }

                GradientStop {
                    position: 1
                    color: "#195cc8"
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    modal_background.visible = false
                    confirm_new_rack_modal.visible = false
                }
            }

            Text {
                id: confirm_scan5
                x: 4
                y: 2
                width: 347
                height: 68
                color: "#ffffff"
                text: qsTr("No")
                font.pixelSize: 47
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.styleName: "Bold"
                font.weight: Font.Bold
                minimumPixelSize: 23
                styleColor: "#011ca1"
                textFormat: Text.PlainText
                style: Text.Raised
                font.family: "Times New Roman"
                font.bold: true
            }
        }
    }
}



/*##^##
Designer {
    D{i:0;formeditorZoom:0.5}D{i:32}
}
##^##*/
