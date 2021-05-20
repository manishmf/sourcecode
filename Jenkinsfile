#!groovy
 
@Library('jenkins-pipeline-utils') _
 
properties([[$class: 'BuildDiscarderProperty',
             strategy: [$class: 'LogRotator',
                        artifactDaysToKeepStr: '4',
                        artifactNumToKeepStr: '',
                        daysToKeepStr: '30',
                        numToKeepStr: '']
            ],
            disableConcurrentBuilds(),
])
 
def flavorsForTest = ["Allianz_IMSInternal"];
//generate_XCtest_Doc = true
xctestdocs_dir = "xctest_docs"
 
notifyProgress("pipeline started")
 
final int ARTIFACT_BUILD_NUMBER = buildNumber.timeBased()
currentBuild.displayName = "#${BUILD_NUMBER} – build number ${ARTIFACT_BUILD_NUMBER}"
 
/*#def rvmSh(String cmd) {
#   def sourceRvm = "$HOME/.rvm/scripts/rvm" 
#   def useRuby = "rvm use 2.5.0"
#   sh "${sourceRvm}; ${useRuby}; $cmd"
#}*/
 
/*def withRvm(String version, String gemset, Closure cl) {
    // First we have to amend the `PATH`.
    final RVM_HOME = '/Users/_jenkins/.rvm'
    paths = [
        "$RVM_HOME/gems/$version@$gemset/bin",
        "$RVM_HOME/gems/$version@global/bin",
        "$RVM_HOME/rubies/$version/bin",
       "$RVM_HOME/bin",
        "${env.PATH}"
    ]
    def path = paths.join(':')
    // First, let's make sure Ruby version is present.
    withEnv(["PATH=${env.PATH}:$RVM_HOME", "RVM_HOME=$RVM_HOME"]) {
        // Having `rvm` command available, `rvm use` can be used directly:
        sh "set +x; source $RVM_HOME/scripts/rvm; rvm use $version@$gemset"
    }
    // Because we've just made sure Ruby is installed and Gemset is present, Ruby env vars can be exported just as `rvm use` would set them.
    withEnv([
        "PATH=$path",
        "GEM_HOME=$RVM_HOME/gems/$version@$gemset",
        "GEM_PATH=$RVM_HOME/gems/$version@$gemset:$RVM_HOME/gems/$version@global",
        "MY_RUBY_HOME=$RVM_HOME/rubies/$version",
        "IRBRC=$RVM_HOME/rubies/$version/.irbrc",
        "RUBY_VERSION=$version"
    ]) {
        // `rvm` can't tell if `rvm use` was run or the env vars were set manually.
        sh 'rvm info'
        sh 'ruby --version'
        cl()
    }
}*/
 
 
node {
    try {
        stage('Checkout') {
            checkout scm
        }
 
        stage('Clean') {
            sh 'git clean -fdx'
            sh 'git reset --hard'
        }
 
        stash name: 'src', excludes: 'TelematicsTester/**'
    } catch (e) {
        notifyFailure("failed to checkout source code", e)
        throw e
    }
}
withRvm('ruby-2.5.0') {
stage('Bootstrap') {
    node('itchy') {
        unstash 'src'
        
        try {
           withEnv(['FASTLANE_DISABLE_COLORS=1']) {
               sh ''' 
                  export LDFLAGS="-L/Users/_jenkins/.rvm/rubies/ruby-2.5.0/lib"
                  export CPPFLAGS="-L/Users/_jenkins/.rvm/rubies/ruby-2.5.0/include" 
                  fastlane bootstrap
               '''
            }
 
 
            withEnv(["SRCROOT=${WORKSPACE}/Prototype"]) {
                sh 'Scripts/git_version_info.sh'
            }
 
            archiveArtifacts '**/licenses.html'
            stash name: 'bootstrapped', includes: ['Prototype/Carthage/Build/**',
                    'Prototype/Podfile.lock',
                    'Prototype/Pods/**',
                    'Prototype/TelematicsPrototype.xc*/**',
                    '**/git.plist'].join(',')
        } catch (e) {
            notifyFailure("failed to build dependencies", e)
            throw e
        }
    }
}
stage('Code Quality') {
    node('itchy') {
        deleteDir()
        unstash 'src'
        unstash 'bootstrapped'
 
        try {
            sh 'mkdir -p fastlane/build'
            sh 'swiftlint lint --config Prototype/.swiftlint.yml --quiet --reporter checkstyle > fastlane/build/swiftlint-results.xml || true'
            checkstyle canComputeNew: false, defaultEncoding: '', healthy: '', pattern: '**/swiftlint-results.xml', unHealthy: ''
        } catch (e) {
            notifyFailure("static code quality analysis failed", e)
            throw e
        }
    }
}
 
stage('Test') {
    node('itchy') {
        deleteDir()
        unstash 'src'
        unstash 'bootstrapped'
 
        lock(resource: nodeResource('simulator'), inversePrecedence: true) {
            //kill any lingering Simulator instances.
            sh 'killall Simulator 2> /dev/null || true'
 
 
        }
    }
}
 
if (false) {
    return
}
 
stage('Build') {
    //splits all the targets to build into 4 groups of approx equal size.
    //each group will be dispatched to a different node, and build simultaneously with the
    //other groups.
    def groups = allTargets().collate((int)Math.ceil((double)(allTargets().size() / 4)))
 
    def buildTasks = [:]
    groups.eachWithIndex { group, i ->
        buildTasks["staging${i}"] = {
            node('itchy') {
                deleteDir()
                unstash 'src'
                unstash 'bootstrapped'
 
                try {
                    withEnv(['FASTLANE_DISABLE_COLORS=1',
                            'FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT=90',
                            'FASTLANE_XCODE_LIST_TIMEOUT=90',
                            'GYM_DERIVED_DATA_PATH=./DerivedData-build']) {
                        sh "fastlane agvtool build_number:${ARTIFACT_BUILD_NUMBER}"
                        sh "fastlane build schemes:${group.join(',')}"
                    }
                } catch (e) {
                    notifyFailure("failed to build artifacts", e)
                    throw e
                }
 
                if (isIntegrationBranch()) {
                    try {
                        archiveArtifacts '**/*.ipa, **/*.dSYM.zip, **/*.xcarchive.tar.gz'
                    } catch (e) {
                        notifyFailure("failed to publish artifacts", e)
                        throw e
                    }
                }
            }
        }
    }
 
    parallel buildTasks
    notifyProgress("published artifacts")
}
}
notifyCompletion()
 
def allTargets() {
    def targets = [
   //      'ADACStaging',
   // 'Allianz_IMSInternalStaging',
   //    'AllianzUATStaging',
         'UBISalesStaging',
   //     'NationwideStaging',
   //     'NationwideRelease',
        'AppiStaging',
   //   'AppiRelease'
  //    'UBISalesRelease',
  //    'UBISales_NJMStaging',
        'FBFSStaging'
   // 'UtahRUCStaging'
    ]
 
   //   targets += 'NJM_External/development'
  //    targets += 'FBFS_External/development'
 
    return targets.sort()
}
 
/**
 Generates a resource name that is local to a single node.
 Jenkins expects resources to be global, and so locking on a resource name will block all
 jobs on all nodes. However, some resources are unique per-node, eg the iOS simulator, and
 acquiring one of these node resources should not block other jobs on other nodes.
 @param [in] label The node-specific resource to acquire.
 @return {@code label} decorated with this node's name
 */
def nodeResource(label) {
    return "${env.NODE_NAME}_${label}"
}
 
def shouldHaltAfterUnitTests() {
    return !isIntegrationBranch()
}
 
def isIntegrationBranch() {
    return env.BRANCH_NAME in ['develop', 'master'] || env.BRANCH_NAME.startsWith('release/')
}
 
def shouldSendFailureNotificationToEveryone() {
    return isIntegrationBranch()
}
 
def generate_XCtest_Doc() {
    return isIntegrationBranch()
}
 
def notifyProgress(event) {
    //do nothing
}
 
def notifyFailure(event, ex = null) {
    print "notifying failure, job status is ${currentBuild.result}"
 
    //the build result is often not set until the caught exception is rethrown.
    //however, that happens after this step.
    if (currentBuild.result == null) {
        if (ex instanceof InterruptedException ||
                    (ex instanceof hudson.AbortException && ex.message.contains("exit code 143"))) {
            currentBuild.result = "ABORTED"
        } else {
            currentBuild.result = "FAILURE"
        }
    }
 
    def message = [
            "PIPELINE STOPPED",
            "Job <${env.BUILD_URL}|${env.JOB_NAME} #${env.BUILD_NUMBER}>",
            "${event}",
            "<${env.BUILD_URL}/console/|${ex}>",
        ].join('\n')
 
    def messageColour = colourForBuildStatus(currentBuild.result)
    if (shouldSendFailureNotificationToEveryone() && messageColour == 'danger') {
        slackSend(channel: "#eng_mobile", color: messageColour, notify: true, message: message)
    }
}
 
def notifyFailedTests() {
    def failCount = numberOfFailedTests()
    if (failCount < 1) {
        return
    }
 
    def message = [
            "TESTS FAILED",
            "Job <${env.BUILD_URL}|${env.JOB_NAME} #${env.BUILD_NUMBER}>",
            ">>> <${env.BUILD_URL}/testReport/|${failCount} tests failed>"
        ].join('\n')
 
    if (shouldSendFailureNotificationToEveryone()) {
        slackSend(channel: "#eng_mobile", color: colourForBuildStatus(currentBuild.result ?: 'FAILURE'), notify: true, message: message)
    }
}
 
def notifyCompletion() {
    if (!shouldNotifyBuildResult(currentBuild.result ?: 'SUCCESS')) {
        return    }
 
    def message = "Job '<${env.BUILD_URL}|${env.JOB_NAME} #${env.BUILD_NUMBER}>' is back to normal!"
    slackSend(channel: "#eng_mobile", color: colourForBuildStatus(currentBuild.result ?: 'SUCCESS'), notify: true, message: message)
}
 
@NonCPS
def shouldNotifyBuildResult(result) {
    print "notifying completion. build status is ${currentBuild.result}"
    if (result != "SUCCESS") {
        print "would notify completion for failed build"
        return false
    }
 
    if (currentBuild.previousBuild == null) {
        print "this is the first build; do not notify"
        return false
    }
 
    if (currentBuild.previousBuild.result in [result, null]) {
        print "last build has the same status; do not need to notify"
        return false
    }
 
    return true
}
 
@NonCPS
def numberOfFailedTests() {
    def testResult = currentBuild.rawBuild.getAction(hudson.tasks.junit.TestResultAction.class)
    if (testResult == null) {
        return 0
    }
 
    return testResult.failCount
}
 
def colourForBuildStatus(status) {
    if (status in ['FAILURE', 'FAILED', 'ERROR']) {
        color = 'danger'
    } else if(status in ['SUCCESS', 'SUCCESSFUL']) {
        color = 'good'
    } else if(status in ['UNSTABLE']) {
        color = 'warning'
    } else {
        color = '#909090'
    }
 
    return color
}
 
 
/**
 Returns UDID of a certain simulator on a current node.
 @param [name] simulator name, e.g. iPhone 6.
 @return UDID of certain simulator
 */
def getsimid(name) {
    //String result = sh(script: "xcrun simctl list devices | grep '" + name +"' | grep -v unavailable | head -1", returnStdout: true)
    String result = sh(script: "instruments -s devices | grep '" + name +"' | grep 10. | grep -v unavailable | head -1", returnStdout: true)
    def test = ~/(.+)\[(.+)\](.+)/
 
    def matcher = (result =~ test)
    echo matcher[0][2]
    return matcher[0][2]
}
 
def withRvm(version, cl) {
    withRvm(version, "executor-${env.EXECUTOR_NUMBER}") {
        cl()
    }
}
 
def withRvm(version, gemset, cl) {
    RVM_HOME='$HOME/.rvm'
    paths = [
        "$RVM_HOME/gems/$version@$gemset/bin",
        "$RVM_HOME/gems/$version@global/bin",
        "$RVM_HOME/rubies/$version/bin",
        "$RVM_HOME/bin",
        "${env.PATH}"
    ]
    def path = paths.join(':')
    withEnv(["PATH=${env.PATH}:$RVM_HOME", "RVM_HOME=$RVM_HOME"]) {
        sh "set +x; source $RVM_HOME/scripts/rvm; rvm use --create --install --binary $version@$gemset"
    }
    withEnv([
        "PATH=$path",
        "GEM_HOME=$RVM_HOME/gems/$version@$gemset",
        "GEM_PATH=$RVM_HOME/gems/$version@$gemset:$RVM_HOME/gems/$version@global",
        "MY_RUBY_HOME=$RVM_HOME/rubies/$version",
        "IRBRC=$RVM_HOME/rubies/$version/.irbrc",
        "RUBY_VERSION=$version"
        ]) {
            sh 'gem install bundler'
            cl()
        }
    }
