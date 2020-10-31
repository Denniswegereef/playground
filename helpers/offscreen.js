// http://stackoverflow.com/questions/17624021/determine-if-a-mesh-is-visible-on-the-viewport-according-to-current-camera

const THREE = require('three')

export default (mesh, camera) => {
  const frustum = new THREE.Frustum()
  const cameraViewProjectionMatrix = new THREE.Matrix4()

  camera.updateMatrixWorld()
  camera.matrixWorldInverse.getInverse(camera.matrixWorld)
  cameraViewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse)
  frustum.setFromProjectionMatrix(cameraViewProjectionMatrix)

  return frustum.intersectsObject(mesh)
}
