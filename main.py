# This Python file uses the following encoding: utf-8
import sys
import os

from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtCore import QObject, Slot, Qt
from PySide2 import QtPrintSupport, QtWidgets, QtGui
from PySide2.QtWidgets import QApplication
import qrcode
import treepoem
import base64
import gzip


class BarcodeUtils(QObject):
    @Slot(str)
    def print_data(self, string):
        print(string)

    @Slot(str, str, str, str)
    def generate_barcode(self, user_barcode, tube_barcode, directory, filename):
        #  print(user_barcode)

        if not os.path.isdir(directory):
            os.makedirs(directory)

        backup_file = open(filename, "w")
        backup_file.write(user_barcode)
        backup_file.write("\n")
        backup_file.write("\n")
        backup_file.write(tube_barcode)
        backup_file.close()

        data_users_bytes = user_barcode.encode()
        encoded_users_data = base64.b64encode(data_users_bytes)

        data_tubes_bytes = tube_barcode.encode()
        encoded_tubes_data = base64.b64encode(data_tubes_bytes)

        compressed_data_users = gzip.compress(encoded_users_data)
        compressed_data_tubes = gzip.compress(encoded_tubes_data)

        # print(compressed_data)
        users_barcode_filename = filename.replace(".json", "_users.png")
        tubes_barcode_filename = filename.replace(".json", "_tubes.png")

        image_users = treepoem.generate_barcode(
          barcode_type='datamatrix',
         data=compressed_data_users,
         options={"width":5,"height":5},
        )
        image_users.convert('1').save(users_barcode_filename)
        image_users.convert('1').save("current_users_barcode.png")

        image_tubes = treepoem.generate_barcode(
          barcode_type='datamatrix',
         data=compressed_data_tubes,
         options={"width":5,"height":5},
        )
        image_tubes.convert('1').save(tubes_barcode_filename)
        image_tubes.convert('1').save("current_tubes_barcode.png")

    @Slot()
    def handle_print(self):
        win = engine.rootObjects()[0]

        printer = QtPrintSupport.QPrinter(QtPrintSupport.QPrinter.HighResolution)
        dialog = QtPrintSupport.QPrintDialog(printer)
        if dialog.exec_() == QtPrintSupport.QPrintDialog.Accepted:
            print("painting")
            painter = QtGui.QPainter(printer)
            image = QtGui.QImage("something.png")

            painter.drawImage(image.rect(), image)
            painter.end()


if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    barcode_utils = BarcodeUtils()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("barcode_utils", barcode_utils)
    engine.load(os.path.join(os.path.dirname(__file__), "main.qml"))

    object = engine.findChild(QObject, "printData")
    win = engine.rootObjects()[0]

    if object is not None:
        print("object is not none" + str(object))

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec_())
