QT += core gui widgets multimedia multimediawidgets network

lessThan(QT_MINOR_VERSION, 6): {
    QT += webkit widgets webkitwidgets
    DEFINES += RHODES_VERSION_1
}
greaterThan(QT_MINOR_VERSION, 6): {
    QT += webengine webenginecore webenginewidgets
    CONFIG += c++14
    DEFINES += CPP_ELEVEN RHODES_VERSION_2
}

TARGET = DocumentPicker
TEMPLATE = lib

CONFIG += staticlib warn_on

isEmpty(RHODES_ROOT) {
  RHODES_ROOT = ../../../../../../rhodes
}

INCLUDEPATH += \
$$RHODES_ROOT/lib/commonAPI/coreapi/ext/shared\
$$RHODES_ROOT/platform/shared/common\
$$RHODES_ROOT/platform/shared/rubyext\
$$RHODES_ROOT/platform/shared/ruby/include\
$$RHODES_ROOT/platform/shared\
../../shared

macx {
  DESTDIR = $$RHODES_ROOT/platform/osx/bin/extensions
  OBJECTS_DIR = $$RHODES_ROOT/platform/osx/bin/extensions/documentpicker
  INCLUDEPATH += $$RHODES_ROOT/platform/shared/ruby/iphone
}
win32 {
  DESTDIR = $$RHODES_ROOT/platform/win32/bin/extensions
  OBJECTS_DIR = $$RHODES_ROOT/platform/win32/bin/extensions/documentpicker 
  DEFINES += WIN32 _WINDOWS _LIB _UNICODE UNICODE WIN32_LEAN_AND_MEAN
  debug {
    DEFINES += _DEBUG DEBUG
  }
  release {
    DEFINES += _NDEBUG NDEBUG
  }
  INCLUDEPATH += $$RHODES_ROOT/platform/shared/ruby/win32
}

DEFINES += RHODES_QT_PLATFORM _XOPEN_SOURCE _DARWIN_C_SOURCE

!isEmpty(RHOSIMULATOR_BUILD) {
  DEFINES += RHODES_EMULATOR
}

!win32 {
  QMAKE_CFLAGS_WARN_ON += -Wno-extra -Wno-unused -Wno-sign-compare -Wno-format -Wno-parentheses
  QMAKE_CXXFLAGS_WARN_ON += -Wno-extra -Wno-unused -Wno-sign-compare -Wno-format -Wno-parentheses
}
win32 {
  QMAKE_CFLAGS_WARN_ON += /wd4996 /wd4100 /wd4005
  QMAKE_CXXFLAGS_WARN_ON += /wd4996 /wd4100 /wd4005
  QMAKE_CFLAGS_RELEASE += /O2
  QMAKE_CXXFLAGS_RELEASE += /O2
}

HEADERS += \
..\..\shared\generated\cpp\IDocumentPicker.h\
..\..\shared\generated\cpp\DocumentPickerBase.h

SOURCES += \
..\..\shared\generated\cpp\DocumentPicker_js_wrap.cpp\
..\..\shared\generated\cpp\DocumentPicker_ruby_wrap.cpp\
..\..\shared\generated\cpp\DocumentPickerBase.cpp\
..\..\shared\generated\DocumentPicker_api_init.cpp\
..\..\shared\generated\DocumentPicker_js_api.cpp\
..\..\shared\generated\DocumentPicker_ruby_api.c\
src\DocumentPicker_impl.cpp
