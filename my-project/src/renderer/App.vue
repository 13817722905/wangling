<template>
  <div id="app">
    <el-button slot="trigger" size="small" @click="openFile" type="primary">选取文件</el-button>
    <router-view></router-view>
  </div>
</template>

<script>
  export default {
    name: 'my-project',
    data: function () {
      return {
        show: true
      }
    },
    methods: {
      openFile () {
        const {shell} = require('electron')
        const dialog = shell.dialog
        exports.openDialog = function (defaultpath, callback) {
          dialog.showOpenDialog({
            defaultPath: defaultpath,
            properties: [
              'openFile'
            ],
            filters: [
              { name: 'zby', extensions: ['json'] }
            ]
          },
          function (res) {
          // 我这个是打开单个文件的
            callback(res[0])
          })
        }
      }
    }
  }
</script>

<style>
  /* CSS */
  .transition-box {
    margin-bottom: 10px;
    width: 200px;
    height: 100px;
    border-radius: 4px;
    background-color: #409EFF;
    text-align: center;
    color: #fff;
    padding: 40px 20px;
    box-sizing: border-box;
    margin-right: 20px;
  }
</style>
