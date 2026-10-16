#include "../../../shared/generated/cpp/DocumentPickerBase.h"
#include "common/RhodesApp.h"
#include <QString>
#include <QFileDialog>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QCoreApplication>

namespace rho {
	using namespace apiGenerator;

	class CDocumentPickerImpl: public CDocumentPickerBase{
	public:
		CDocumentPickerImpl(const rho::String& strID): CDocumentPickerBase(){}

		virtual void pickDocument(const rho::String& supportedExtensionList, rho::apiGenerator::CMethodResult& oResult){
			rho::Hashtable<rho::String, rho::String> return_map;
			QString fileName = QFileDialog::getOpenFileName(0, "Attach File", "/", convertExtensions(supportedExtensionList, ","));

			QDir dir = QDir(QString::fromUtf8(RHODESAPP().getBlobsDirPath().c_str()));
			if (!dir.exists()) {
				dir.mkpath(dir.absolutePath());
			}
			QFileInfo fInfo(fileName);
			QString newFileName = dir.absolutePath() + "/" + fInfo.fileName();

			if(fInfo.isFile() && !newFileName.isEmpty() && QFile::copy(fileName,newFileName)){
				return_map.put("status", "success");	
				return_map.put("filePath", newFileName.toUtf8().constData());
				LOG(INFO) +  L"Operation successfull";
			}else{
				return_map.put("status", "cancel");	
				return_map.put("filePath", "");
				LOG(INFO) +  L"Operation cancelled";
			}
			oResult.set(return_map);
		}

		QString convertExtensions(const rho::String& text, const rho::String& sep) {
			rho::String convertExt;
			std::size_t start = 0, end = 0;
			while ((end = text.find(sep, start)) != rho::String::npos) {
				if (end != start) {
					convertExt = convertExt + "*." + (text.substr(start, end - start) + " ");
				}
				start = end + 1;
			}
			if (end != start) {
				convertExt = convertExt + "*." + (text.substr(start));
			}
			QString str = QString::fromUtf8(convertExt.c_str());
			return str;
		}
	};

	class CDocumentPickerSingleton: public CDocumentPickerSingletonBase{
		~CDocumentPickerSingleton(){}
		virtual rho::String getInitialDefaultID();
		virtual void enumerate(CMethodResult& oResult);
	};

	class CDocumentPickerFactory: public CDocumentPickerFactoryBase{
		~CDocumentPickerFactory(){}
		virtual IDocumentPickerSingleton* createModuleSingleton();
		virtual IDocumentPicker* createModuleByID(const rho::String& strID);
	};

	extern "C" void Init_DocumentPicker_extension(){
		CDocumentPickerFactory::setInstance( new CDocumentPickerFactory() );
		Init_DocumentPicker_API();
	}

	IDocumentPicker* CDocumentPickerFactory::createModuleByID(const rho::String& strID){
		return new CDocumentPickerImpl(strID);
	}

	IDocumentPickerSingleton* CDocumentPickerFactory::createModuleSingleton(){
		return new CDocumentPickerSingleton();
	}

	void CDocumentPickerSingleton::enumerate(CMethodResult& oResult){
		rho::Vector<rho::String> arIDs;
		arIDs.addElement("SC1");
		arIDs.addElement("SC2");

		oResult.set(arIDs);
	}

	rho::String CDocumentPickerSingleton::getInitialDefaultID(){
		CMethodResult oRes;
		enumerate(oRes);

		rho::Vector<rho::String>& arIDs = oRes.getStringArray();

		return arIDs[0];
	}
}
