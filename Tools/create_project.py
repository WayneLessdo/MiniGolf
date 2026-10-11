from pathlib import Path
import hashlib,json

root=Path(__file__).resolve().parents[1]
project=root/'FoldPutt.xcodeproj'
if project.exists(): raise SystemExit('Project exists; refusing overwrite')
objects={}
def uid(name):return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def add(key,isa,**props):
 i=uid(key);objects[i]={'isa':isa,**props};return i
def literal(value):
 if isinstance(value,dict):return '{ '+ ' '.join(f'{literal(k)} = {literal(v)};' for k,v in value.items())+' }'
 if isinstance(value,list):return '( '+', '.join(literal(v) for v in value)+' )'
 if isinstance(value,int):return str(value)
 return json.dumps(str(value),ensure_ascii=False)
groups=[];sources=[]
for folder in ['App','Models','Views','Systems','Resources']:
 for f in sorted((root/folder).rglob('*.swift')):
  ref=add(str(f)+'ref','PBXFileReference',lastKnownFileType='sourcecode.swift',path=str(f.relative_to(root)),sourceTree='<group>')
  groups.append(ref);sources.append(add(str(f)+'build','PBXBuildFile',fileRef=ref))
catalog=add('catalog','PBXFileReference',lastKnownFileType='folder.assetcatalog',path='Resources/Assets.xcassets',sourceTree='<group>');groups.append(catalog)
res=add('catalog-build','PBXBuildFile',fileRef=catalog)
products=[];targets=[]
def configlist(name,base):
 configs=[]
 for mode in ['Debug','Release']:
  settings=dict(base)
  if mode=='Debug':settings.update({'SWIFT_OPTIMIZATION_LEVEL':'-Onone','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG $(inherited)','ENABLE_TESTABILITY':'YES'})
  else:settings.update({'SWIFT_COMPILATION_MODE':'wholemodule'})
  configs.append(add(name+mode,'XCBuildConfiguration',buildSettings=settings,name=mode))
 return add(name+'configs','XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
base={'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'18.0','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','SWIFT_STRICT_CONCURRENCY':'complete','CODE_SIGN_STYLE':'Automatic','TARGETED_DEVICE_FAMILY':'1,2','PRODUCT_NAME':'$(TARGET_NAME)','GENERATE_INFOPLIST_FILE':'NO'}
appbase=dict(base,PRODUCT_BUNDLE_IDENTIFIER='com.foldputt.prototype',INFOPLIST_FILE='App/Info.plist',ASSETCATALOG_COMPILER_APPICON_NAME='AppIcon',LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/Frameworks')
appProduct=add('appProduct','PBXFileReference',explicitFileType='wrapper.application',path='FoldPutt.app',sourceTree='BUILT_PRODUCTS_DIR');products.append(appProduct)
app=add('app','PBXNativeTarget',buildConfigurationList=configlist('app',appbase),buildPhases=[add('srcPhase','PBXSourcesBuildPhase',buildActionMask=2147483647,files=sources,runOnlyForDeploymentPostprocessing=0),add('resPhase','PBXResourcesBuildPhase',buildActionMask=2147483647,files=[res],runOnlyForDeploymentPostprocessing=0),add('frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)],buildRules=[],dependencies=[],name='FoldPutt',productName='FoldPutt',productReference=appProduct,productType='com.apple.product-type.application');targets.append(app)
testIDs=[]
for folder,name,ui in [('Tests','FoldPuttTests',False),('UITests','FoldPuttUITests',True)]:
 files=[]
 for f in (root/folder).glob('*.swift'):
  ref=add(str(f)+'ref','PBXFileReference',lastKnownFileType='sourcecode.swift',path=str(f.relative_to(root)),sourceTree='<group>');groups.append(ref);files.append(add(str(f)+'build','PBXBuildFile',fileRef=ref))
 product=add(name+'product','PBXFileReference',explicitFileType='wrapper.cfbundle',path=name+'.xctest',sourceTree='BUILT_PRODUCTS_DIR');products.append(product)
 testbase=dict(base,PRODUCT_BUNDLE_IDENTIFIER='com.foldputt.'+name,GENERATE_INFOPLIST_FILE='YES',LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/Frameworks @loader_path/Frameworks')
 if ui:testbase['TEST_TARGET_NAME']='FoldPutt'
 else:testbase.update({'TEST_HOST':'$(BUILT_PRODUCTS_DIR)/FoldPutt.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/FoldPutt','BUNDLE_LOADER':'$(TEST_HOST)'})
 proxy=add(name+'proxy','PBXContainerItemProxy',containerPortal=uid('project'),proxyType=1,remoteGlobalIDString=app,remoteInfo='FoldPutt')
 dep=add(name+'dep','PBXTargetDependency',target=app,targetProxy=proxy)
 target=add(name,'PBXNativeTarget',buildConfigurationList=configlist(name,testbase),buildPhases=[add(name+'src','PBXSourcesBuildPhase',buildActionMask=2147483647,files=files,runOnlyForDeploymentPostprocessing=0)],buildRules=[],dependencies=[dep],name=name,productName=name,productReference=product,productType='com.apple.product-type.bundle.ui-testing' if ui else 'com.apple.product-type.bundle.unit-test')
 targets.append(target);testIDs.append((name,target))
productGroup=add('products','PBXGroup',children=products,name='Products',sourceTree='<group>')
main=add('mainGroup','PBXGroup',children=groups+[productGroup],sourceTree='<group>')
add('project','PBXProject',attributes={'LastUpgradeCheck':'2710'},buildConfigurationList=configlist('project',{'CLANG_ENABLE_MODULES':'YES','SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'18.0'}),compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','zh-Hans','Base'],mainGroup=main,productRefGroup=productGroup,projectDirPath='',projectRoot='',targets=targets)
project.mkdir()
(project/'project.pbxproj').write_text('// !$*UTF8*$!\n'+literal({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':objects,'rootObject':uid('project')}))
def reference(name,i):return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{i}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:FoldPutt.xcodeproj"/>'
scheme=f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2710" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference('FoldPutt',app)}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>'''
for name,i in testIDs:scheme+=f'<TestableReference skipped="NO">{reference(name,i).replace(name+".app",name+".xctest")}</TestableReference>'
scheme+=f'''</Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference('FoldPutt',app)}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference('FoldPutt',app)}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>'''
p=project/'xcshareddata/xcschemes';p.mkdir(parents=True);(p/'FoldPutt.xcscheme').write_text(scheme)
print('Created app + unit/UI test targets, shared FoldPutt scheme.')
