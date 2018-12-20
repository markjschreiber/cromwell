package cromwell.webservice.routes

import cats.implicits._
import spray.json._

object DagAssembly extends DefaultJsonProtocol {

  final case class RgbAverage(rTotal: Long, rCount: Int, gTotal: Long, gCount: Int, bTotal: Long, bCount: Int) {
    private def hexify(total: Long, count: Int): String = {
      val result = (total / count).toHexString.toUpperCase
      if (result.length == 0) "00" + result else if (result.length == 1) "0" + result else result
    }
    def dotString = s"#${hexify(rTotal, rCount)}${hexify(gTotal, gCount)}${hexify(bTotal, bCount)}"
  }
  object RgbAverage {
    def apply(r: Int, g: Int, b: Int): RgbAverage = RgbAverage(r.longValue(), 1, g.longValue(), 1, b.longValue(), 1)
  }
  implicit val rgbAverageMonoid = cats.derived.MkMonoid[RgbAverage]

  /**
    * Convert the 'calls' object from metadata into a mapping of call name to status color.
    */
  def callsToFillColors(calls: Map[String, JsValue]): Map[String, JsString] = calls map { case (fqn, value) =>
    val name = fqn.split('.').last

    val array = value.convertTo[List[JsValue]]
    val fillColor = if (array.nonEmpty) {
      array.foldMap { callEntry =>
        callEntry.asJsObject.fields("executionStatus").convertTo[String] match {
          case "Done" => RgbAverage(0x00, 0x80, 0x01)
          case "QueuedInCromwell" => RgbAverage(0x7F, 0xFF, 0xD4)
          case "Running" => RgbAverage(0x64, 0x95, 0xED)
          case _ => RgbAverage(0xFF, 0x00, 0x00)
        }
      }
    } else {
      RgbAverage(0xD3, 0xD3, 0xD3)
    }

    s"CALL_$name" -> JsString(fillColor.dotString)
  }
}
