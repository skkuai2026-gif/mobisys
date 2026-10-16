#include "../../../shared/generated/cpp/DocumentPickerBase.h"

namespace rho {
	using namespace apiGenerator;

	class CDocumentPickerImpl: public CDocumentPickerBase{
	public:
		CDocumentPickerImpl(const rho::String& strID): CDocumentPickerBase(){}

		virtual void pickDocument(const rho::String& supportedExtensionList, rho::apiGenerator::CMethodResult& oResult){
			rho::Hashtable<rho::String, rho::String> return_map;
			return_map.put("status","status");	
			return_map.put("filePath","filePath");
			// LOG(INFO) +  L"Duration cannot be changed during Wave capture";
			oResult.set(return_map);
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